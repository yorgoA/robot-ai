*** Settings ***
Documentation
...    Scenario: Profile API
...
...    Uses its own dedicated account since Step 3 permanently changes its password.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup         Register A Dedicated API Test Account
Test Setup          Log    --- ${TEST NAME} ---    console=True
Test Teardown       Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Variables ***
${PROFILE_API_EMAIL}       ${NONE}
${PROFILE_API_PASSWORD}    Test123!


*** Keywords ***
Register A Dedicated API Test Account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    ${email}=     Set Variable    robot-ai.profile-api.${suffix}@example.com
    Set Suite Variable    ${PROFILE_API_EMAIL}    ${email}
    I Register A Unique API Test Account    ${email}    ${PROFILE_API_PASSWORD}


*** Test Cases ***
Step 1 - GET Profile Returns The Registered Email
    [Documentation]    A freshly-registered account's profile reflects the email it signed up
    ...                with, and no password hash leaks into the response.
    [Tags]    api    profile    smoke
    I Request My Profile Via API
    The Response Status Should Be "200"
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Equal As Strings    ${body}[email]    ${PROFILE_API_EMAIL}
    Dictionary Should Not Contain Key    ${body}    password_hash

Step 2 - PUT Profile Updates Name And Address
    [Documentation]    Updated fields are reflected in the response and persist on a re-fetch.
    [Tags]    api    profile
    I Update My Profile Via API    name=API Tester    email=${PROFILE_API_EMAIL}    address=42 Endpoint Ave
    The Response Status Should Be "200"

    I Request My Profile Via API
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Equal As Strings    ${body}[name]       API Tester
    Should Be Equal As Strings    ${body}[address]    42 Endpoint Ave

Step 3 - PUT Password Rejects The Wrong Current Password
    [Documentation]    The backend re-validates the current password rather than trusting the
    ...                caller.
    [Tags]    api    profile    negative
    I Change My Password Via API    current_password=not-the-real-password    new_password=NewApiPass1!
    The Response Status Should Be "401"

Step 4 - PUT Password Succeeds With The Correct Current Password
    [Documentation]    A correct current password changes it, and the account can log in with
    ...                the new one.
    [Tags]    api    profile    smoke
    I Change My Password Via API    current_password=${PROFILE_API_PASSWORD}    new_password=NewApiPass1!
    The Response Status Should Be "200"

    ${body}=    Create Dictionary    email=${PROFILE_API_EMAIL}    password=NewApiPass1!
    ${res}=     POST On Session    shopdemo    /login    json=${body}
    The Response Status Is    ${res}    200
