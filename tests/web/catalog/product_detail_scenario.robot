*** Settings ***
Documentation
...    Scenario: Product Detail Page
...
...    Suite Setup logs in and clears the cart, since catalog_scenario.robot (which runs
...    just before this suite, alphabetically) leaves an item in the shared account's cart
...    and Step 3 here asserts an exact badge count.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource
Resource            ../../../resources/common_test_cases/given/given.robot

Suite Setup          A Logged-In User Session Is Started With Empty Cart
Suite Teardown       Close Browser Session
Test Setup           Capture Step Start
Test Teardown        Run Keyword If Test Failed    Take Screenshot On Failure


*** Test Cases ***
Step 1 - Clicking A Product Opens Its Detail Page
    [Documentation]    Navigating from the catalog shows the same product's name, price,
    ...                and stock on its own page.
    [Tags]    catalog    smoke
    I Am On The Product Catalog
    ${name}=    Get Text    ${SEL_PRODUCT_NAME} >> nth=0
    Click       ${SEL_PRODUCT_NAME_LINK} >> nth=0
    Wait For Elements State    ${SEL_PRODUCT_DETAIL_PAGE}    visible    timeout=${DEFAULT_TIMEOUT}
    The Product Detail Page Should Show "${name}"

Step 2 - Quantity Can Be Adjusted With The +/- Controls
    [Documentation]    The quantity stepper increments and decrements, and never drops below 1.
    [Tags]    catalog
    The Quantity Field Should Show "1"
    I Increase The Quantity
    I Increase The Quantity
    The Quantity Field Should Show "3"
    I Decrease The Quantity
    The Quantity Field Should Show "2"

Step 3 - Adding To Cart From The Detail Page Updates The Cart Badge
    [Documentation]    Add to Cart on the detail page behaves the same as from the catalog card.
    [Tags]    catalog    cart    smoke
    I Click The Add To Cart Button
    I Should See The Add To Cart Feedback
    The Cart Badge Should Show "2"
