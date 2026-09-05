*** Settings ***
Documentation
...    Scenario: Orders API
...
...    Uses its own dedicated account so order history starts empty and predictable.
Resource            ../../../resources/keywords/given.resource
Resource            ../../../resources/keywords/when.resource
Resource            ../../../resources/keywords/then.resource

Suite Setup          Register A Dedicated API Test Account
Test Setup           Log    --- ${TEST NAME} ---    console=True
Test Teardown        Run Keyword If Test Failed    Log    STEP FAILED\: ${TEST NAME}    console=True


*** Keywords ***
Register A Dedicated API Test Account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:12]    uuid
    ${email}=     Set Variable    robot-ai.orders-api.${suffix}@example.com
    I Register A Unique API Test Account    ${email}


*** Test Cases ***
Step 1 - A New Account's Order History Starts Empty
    [Documentation]    GET /orders on a fresh account returns an empty list.
    [Tags]    api    orders    smoke
    I Request My Order History Via API
    The Response Status Should Be "200"
    The Response Body Should Be A List
    ${body}=    Set Variable    ${RESPONSE.json()}
    Should Be Empty    ${body}

Step 2 - A Placed Order Appears In History With Its Items
    [Documentation]    After checkout, GET /orders returns the order with its line items intact.
    [Tags]    api    orders    smoke
    I Add A Product To The Cart Via API    product_id=1    quantity=2
    I Submit The Checkout Via API
    The Response Status Should Be "201"

    I Request My Order History Via API
    The Response Status Should Be "200"
    ${body}=    Set Variable    ${RESPONSE.json()}
    Length Should Be    ${body}    1
    Should Be Equal As Integers    ${body}[0][items][0][quantity]    2
