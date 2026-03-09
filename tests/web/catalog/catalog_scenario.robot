*** Settings ***
Documentation
...    Scenario: Product Catalog Browsing
...
...    Suite Setup logs in once. Steps advance through catalog interactions in order.
...    Suite Teardown closes the browser, leaving the app in a clean state.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource
Resource            ../../../resources/common_test_cases/given/given.robot

Suite Setup         A Logged-In User Session Is Started
Suite Teardown      Close Browser Session
Test Setup          Capture Step Start
Test Teardown       Run Keyword If Test Failed    Take Screenshot On Failure


*** Test Cases ***
Step 1 - Catalog Displays Products After Login
    [Documentation]    The home page must show at least one product card when the user is authenticated.
    [Tags]    catalog    smoke
    Given I Am On The Product Catalog
    Then The Catalog Should Show Products

Step 2 - A Product Can Be Added To The Cart From The Catalog
    [Documentation]    Clicking "Add to Cart" on the first product updates the cart badge.
    [Tags]    catalog    cart    smoke
    Given I Am On The Product Catalog
    When I Add The First Product To My Cart
    Then The Cart Badge Should Show "1"
