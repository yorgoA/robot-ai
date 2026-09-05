*** Settings ***
Documentation
...    Scenario: User Registration
...
...    Each test uses its own unique email since Register creates a new account
...    that persists in the database - reusing one email across runs would only
...    pass once.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource
Library             Collections

Suite Setup          Open Browser To App
Suite Teardown       Close Browser Session
Test Setup           I Am On The Register Page
Test Teardown        Run Keyword If Test Failed    Take Screenshot On Failure


*** Keywords ***
A Unique Test Email
    [Documentation]    Uses a random suffix rather than a timestamp - two calls in the same
    ...                test run can land in the same second and would otherwise collide.
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    RETURN    robot-ai.register.${suffix}@example.com


*** Test Cases ***
Step 1 - Mismatched Passwords Are Rejected
    [Documentation]    Confirm-password must match password, or registration is blocked
    ...                client-side before any request is sent.
    [Tags]    register    negative    validation
    ${email}=    A Unique Test Email
    I Register With Email "${email}" Password "Test123!" And Confirm "Different123!"
    I Should See Register Error Containing "match"
    I Should Be On The Register Page

Step 2 - A New Account Can Register And Is Logged In Immediately
    [Documentation]    A successful registration logs the user in and lands on the catalog.
    [Tags]    register    smoke
    ${email}=    A Unique Test Email
    I Register With Email "${email}" Password "Test123!" And Confirm "Test123!"
    I Should Be Logged In
    The Catalog Should Show Products

Step 3 - Registering An Already-Used Email Is Rejected
    [Documentation]    The same email can't be registered twice.
    [Tags]    register    negative
    ${email}=    A Unique Test Email
    I Register With Email "${email}" Password "Test123!" And Confirm "Test123!"
    I Should Be Logged In
    I Click Logout
    I Am On The Register Page
    I Register With Email "${email}" Password "Test123!" And Confirm "Test123!"
    I Should See A Register Error
    I Should Be On The Register Page
