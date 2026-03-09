*** Settings ***
Documentation
...    Scenario: User Login
...
...    Tests run in order — each step advances the scenario state.
...    Suite Setup opens a single browser session shared across all steps.
...    Suite Teardown closes the browser, resetting state for the next run.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup         Open Browser To App
Suite Teardown      Close Browser Session
Test Setup          Capture Step Start
Test Teardown       Run Keyword If Test Failed    Take Screenshot On Failure


*** Test Cases ***
Step 1 - Empty Fields Are Rejected
    [Documentation]    Submitting the login form with no input should keep the user on the login page.
    [Tags]    auth    login    validation
    Given I Am On The Login Page
    When I Submit Empty Credentials
    Then I Should Be On The Login Page
    And I Should Not Be Logged In

Step 2 - Invalid Credentials Are Rejected
    [Documentation]    Wrong email/password should display an error and keep the user on the login page.
    [Tags]    auth    login    negative
    Given I Am On The Login Page
    When I Submit Invalid Credentials
    Then I Should See A Login Error
    And I Should Not Be Logged In

Step 3 - Valid Credentials Grant Access
    [Documentation]    Correct credentials should authenticate the user and show the main application.
    [Tags]    auth    login    smoke
    Given I Am On The Login Page
    When I Submit Valid Credentials
    Then I Should Be Logged In
