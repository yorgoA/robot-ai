*** Settings ***
Documentation
...    Scenario: Authentication API
...
...    Steps advance from failure cases to success. An unauthenticated session
...    is created in Suite Setup. No teardown needed — no state is modified.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup         I Create An API Session
Test Setup          Log    --- ${TEST NAME} ---    console=True
Test Teardown       Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Test Cases ***
Step 1 - Invalid Credentials Are Rejected
    [Documentation]    POST /login with wrong credentials must return HTTP 401.
    [Tags]    api    auth    negative
    When I Login Via API With Invalid Credentials
    Then The Response Status Should Be "401"

Step 2 - Valid Credentials Return A Token
    [Documentation]    POST /login with correct credentials must return HTTP 200 and a JWT token.
    [Tags]    api    auth    smoke
    When I Login Via API With Valid Credentials
    Then The Response Status Should Be "200"
    And The Response Should Contain Key "token"
