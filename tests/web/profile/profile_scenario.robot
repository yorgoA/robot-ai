*** Settings ***
Documentation
...    Scenario: Profile Editing And Password Change
...
...    Uses its own freshly-registered account rather than the shared VALID_EMAIL
...    one, since Step 3 permanently changes that account's password - reusing the
...    shared account here would break every other suite that logs in with it.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup          Register A Dedicated Test Account
Suite Teardown       Close Browser Session
Test Setup           I Am On My Profile Page
Test Teardown        Run Keyword If Test Failed    Take Screenshot On Failure


*** Variables ***
${PROFILE_TEST_EMAIL}       ${NONE}
${PROFILE_TEST_PASSWORD}    Test123!


*** Keywords ***
Register A Dedicated Test Account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    ${email}=     Set Variable    robot-ai.profile.${suffix}@example.com
    Set Suite Variable    ${PROFILE_TEST_EMAIL}    ${email}
    I Register A Unique Account And Log In    ${email}    ${PROFILE_TEST_PASSWORD}


*** Test Cases ***
Step 1 - Profile Shows The Account's Email
    [Documentation]    The profile form loads pre-filled with the logged-in account's email.
    [Tags]    profile    smoke
    My Profile Should Show Email "${PROFILE_TEST_EMAIL}"

Step 2 - Name And Address Can Be Updated
    [Documentation]    Saving the profile form persists the new name and address.
    [Tags]    profile    smoke
    I Update My Profile Name To "Robot Tester" And Address To "1 Automation Way"
    I Should See A Profile Success Message
    Reload
    Wait For Elements State    ${SEL_PROFILE_NAME_INPUT}    visible    timeout=${DEFAULT_TIMEOUT}
    ${name}=    Get Property    ${SEL_PROFILE_NAME_INPUT}    value
    Should Be Equal As Strings    ${name}    Robot Tester

Step 3 - Password Change Is Rejected With The Wrong Current Password
    [Documentation]    Confirms the backend re-checks the current password server-side, not
    ...                just client-side confirm-match.
    [Tags]    profile    password    negative
    I Change My Password From "not-the-real-password" To "NewPass123!" Confirming "NewPass123!"
    I Should See A Password Error

Step 4 - Password Change Succeeds And The New Password Works
    [Documentation]    A correct current password lets the change through, and the account
    ...                can log back in with the new one.
    [Tags]    profile    password    smoke
    I Change My Password From "${PROFILE_TEST_PASSWORD}" To "NewPass123!" Confirming "NewPass123!"
    I Should See A Password Success Message

    I Click Logout
    I Am On The Login Page
    I Enter Email "${PROFILE_TEST_EMAIL}"
    I Enter Password "NewPass123!"
    I Click The Login Button
    I Should Be Logged In
