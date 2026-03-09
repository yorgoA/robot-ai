*** Settings ***
Documentation
...    Scenario: Checkout API
...
...    Steps advance from the rejection case to the success case.
...    Suite Setup authenticates and ensures the cart starts empty.
...    Suite Teardown clears the cart so the scenario is re-runnable.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup         Run Keywords
...                 I Am Authenticated To The API    AND
...                 I Clear My Cart Via API
Suite Teardown      I Clear My Cart Via API
Test Setup          Log    --- ${TEST NAME} ---    console=True
Test Teardown       Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Test Cases ***
Step 1 - Checkout Is Rejected When The Cart Is Empty
    [Documentation]    POST /checkout with no items must return HTTP 400.
    [Tags]    api    checkout    negative
    When I Submit The Checkout Via API With An Empty Cart
    Then The Response Status Should Be "400"

Step 2 - Checkout Succeeds When The Cart Has Items
    [Documentation]    Adding a product and posting to /checkout must return HTTP 200 with an orderId.
    [Tags]    api    checkout    smoke
    Given I Add A Product To The Cart Via API
    When I Submit The Checkout Via API
    Then The Response Status Should Be "201"
    And The Response Should Contain Key "orderId"
