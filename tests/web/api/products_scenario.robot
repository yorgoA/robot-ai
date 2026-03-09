*** Settings ***
Documentation
...    Scenario: Products API
...
...    Products endpoint requires no auth. Steps verify list shape then field integrity.
...    Suite Setup creates an unauthenticated session. No teardown needed.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup         I Create An API Session
Test Setup          Log    --- ${TEST NAME} ---    console=True
Test Teardown       Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Test Cases ***
Step 1 - Products Endpoint Returns A Non-Empty List
    [Documentation]    GET /products must return HTTP 200 and at least one product.
    [Tags]    api    products    smoke
    When I Request The Products List
    Then The Response Status Should Be "200"
    And The Response Body Should Be A List
    And The Response Body Should Not Be Empty

Step 2 - Every Product Has The Required Fields
    [Documentation]    Each item in the product list must have id, name, and price fields.
    [Tags]    api    products
    When I Request The Products List
    Then Each Product Should Have Field "id"
    And Each Product Should Have Field "name"
    And Each Product Should Have Field "price"
