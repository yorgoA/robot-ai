*** Settings ***
Documentation
...    Scenario: Cart and Checkout Flow
...
...    Steps run in order — state accumulates across test cases intentionally.
...    Suite Setup clears the cart and logs in so the scenario always starts from an empty cart.
...    Suite Teardown closes the browser. The cart is empty because Step 3 places an order (clearing it).
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource
Resource            ../../../resources/common_test_cases/given/given.robot
Resource            ../../../resources/common_test_cases/when/when.robot
Resource            ../../../resources/common_test_cases/then/then.robot

Suite Setup         A Logged-In User Session Is Started With Empty Cart
Suite Teardown      Close Browser Session
Test Setup          Capture Step Start
Test Teardown       Run Keyword If Test Failed    Take Screenshot On Failure


*** Test Cases ***
Step 1 - A Product Can Be Added To The Cart
    [Documentation]    Adding a product from the catalog should increment the cart badge to 1.
    [Tags]    cart    smoke
    Given I Am On The Product Catalog
    When I Add The First Product To My Cart
    Then The Cart Badge Should Show "1"

Step 2 - The Cart Reflects The Added Item
    [Documentation]    Navigating to the cart should show the item added in Step 1.
    [Tags]    cart    smoke
    Given I Navigate To My Cart
    Then My Cart Should Have Items

Step 3 - Checkout Completes The Purchase
    [Documentation]    Clicking Checkout from the cart should place the order and show a confirmation.
    [Tags]    checkout    smoke
    When I Click Checkout
    Then The Purchase Was Successful
