*** Settings ***
Documentation
...    Scenario: Cart API
...
...    Uses its own dedicated account so cart contents never collide with the
...    shared VALID_EMAIL account used elsewhere.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup          Register A Dedicated API Test Account
Test Setup           Log    --- ${TEST NAME} ---    console=True
Test Teardown        Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Keywords ***
Register A Dedicated API Test Account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    ${email}=     Set Variable    robot-ai.cart-api.${suffix}@example.com
    I Register A Unique API Test Account    ${email}


*** Test Cases ***
Step 1 - A New Account's Cart Starts Empty
    [Documentation]    GET /cart on a fresh account returns an empty list.
    [Tags]    api    cart    smoke
    I Request The Cart Via API
    The Response Status Should Be "200"
    The Response Body Should Be A List
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Empty    ${body}

Step 2 - Adding A Product Appears In The Cart
    [Documentation]    POST /cart/add returns 200, and the item then shows up in GET /cart.
    [Tags]    api    cart    smoke
    I Add A Product To The Cart Via API    product_id=1    quantity=2
    The Response Status Should Be "200"

    I Request The Cart Via API
    ${body}=    Set Variable    ${RESPONSE.json()}
    Length Should Be    ${body}    1
    Should Be Equal As Integers    ${body}[0][quantity]    2

Step 3 - Updating The Quantity Changes The Cart
    [Documentation]    POST /cart/update changes the stored quantity for that item.
    [Tags]    api    cart
    I Update The Cart Quantity Via API    product_id=1    quantity=5
    The Response Status Should Be "200"

    I Request The Cart Via API
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Equal As Integers    ${body}[0][quantity]    5

Step 4 - Removing The Item Empties The Cart
    [Documentation]    POST /cart/remove takes the item back out.
    [Tags]    api    cart
    I Remove A Product From The Cart Via API    product_id=1
    The Response Status Should Be "200"

    I Request The Cart Via API
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Empty    ${body}

Step 5 - Adding More Than Available Stock Is Rejected
    [Documentation]    The API enforces the stock limit itself - not just the UI.
    [Tags]    api    cart    negative
    I Add A Product To The Cart Via API    product_id=1    quantity=999999
    The Response Status Should Be "400"
