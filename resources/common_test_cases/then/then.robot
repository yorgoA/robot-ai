*** Settings ***
Documentation    Composite Then (assertion) flows shared across test suites.
Resource         ../../keywords/then.resource


*** Keywords ***
The Purchase Was Successful
    [Documentation]    Verifies the order success banner and order ID are shown.
    The Order Should Be Confirmed
    The Order ID Should Be Displayed
