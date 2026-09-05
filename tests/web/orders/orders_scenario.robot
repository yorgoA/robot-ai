*** Settings ***
Documentation
...    Scenario: Order History
...
...    Uses its own freshly-registered account so Step 1 can reliably assert an
...    empty order history - the shared VALID_EMAIL account accumulates orders
...    from the cart/checkout suite and can't be used for that assertion.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup          Register A Dedicated Test Account
Suite Teardown       Close Browser Session
Test Setup           Capture Step Start
Test Teardown        Run Keyword If Test Failed    Take Screenshot On Failure


*** Keywords ***
Register A Dedicated Test Account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    ${email}=     Set Variable    robot-ai.orders.${suffix}@example.com
    I Register A Unique Account And Log In    ${email}    Test123!


*** Test Cases ***
Step 1 - A New Account Has No Orders Yet
    [Documentation]    A freshly-registered account's order history starts empty.
    [Tags]    orders    smoke
    I Am On My Orders Page
    I Should See The Empty Orders State

Step 2 - Placing An Order Makes It Appear In History
    [Documentation]    Adds a product and checks out via the API (faster and already covered
    ...                end to end by the UI in the cart/checkout suite), then confirms the UI
    ...                order-history page reflects it.
    [Tags]    orders    smoke
    I Add A Product To The Cart Via API    product_id=1    quantity=1
    I Submit The Checkout Via API
    The Response Status Should Be "201"

    I Am On My Orders Page
    My Order History Should Contain "1" Order

Step 3 - The Receipt Can Be Downloaded
    [Documentation]    Downloading a receipt produces a real file via the browser's download
    ...                mechanism, not just a rendered element.
    [Tags]    orders    receipt
    I Am On My Orders Page
    I Download The Receipt For The First Order
    The Downloaded Receipt Should Be Named "receipt-order-*.txt"
