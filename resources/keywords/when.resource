*** Settings ***
Documentation
...    WHEN keywords — user actions, form interactions, API requests.
...    A QA adding a new action keyword adds it HERE.
Library     Browser
Library     RequestsLibrary
Library     Collections
Resource    ../locators/login.resource
Resource    ../locators/catalog.resource
Resource    ../locators/cart.resource
Resource    ../variables.robot


*** Keywords ***
# ── Login / Register actions ───────────────────────────────────────────────────

I Enter Email "${email}"
    Type Text    ${SEL_EMAIL_INPUT}    ${email}    clear=True

I Enter Password "${password}"
    Type Text    ${SEL_PASSWORD_INPUT}    ${password}    clear=True

I Click The Login Button
    Click    ${SEL_LOGIN_BUTTON}

I Submit Valid Credentials
    I Enter Email "${VALID_EMAIL}"
    I Enter Password "${VALID_PASSWORD}"
    I Click The Login Button

I Submit Invalid Credentials
    I Enter Email "${INVALID_EMAIL}"
    I Enter Password "${INVALID_PASSWORD}"
    I Click The Login Button

I Submit Empty Credentials
    I Click The Login Button

I Click Logout
    Click    ${SEL_LOGOUT_BUTTON}

# ── Catalog actions ────────────────────────────────────────────────────────────

I Add The First Product To My Cart
    Wait For Elements State     ${SEL_ADD_TO_CART_BTN} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}
    Click                       ${SEL_ADD_TO_CART_BTN} >> nth=0

I Set Quantity To "${qty}"
    Fill Text    ${SEL_QUANTITY_INPUT}    ${qty}

I Click The Cart Icon
    Click    ${SEL_NAV_CART}

# ── Cart / Checkout actions ────────────────────────────────────────────────────

I Clear My Cart Via API
    [Documentation]    Removes all items from the current user's cart via the API.
    ...                 Requires an authenticated session (shopdemo_auth) to already exist.
    ${res}=     GET On Session    shopdemo_auth    /cart
    FOR    ${item}    IN    @{res.json()}
        ${body}=    Create Dictionary    productId=${item}[product_id]
        POST On Session    shopdemo_auth    /cart/remove    json=${body}
    END

I Click Checkout
    Wait For Elements State     ${SEL_CHECKOUT_BUTTON}    visible    timeout=${DEFAULT_TIMEOUT}
    Click                       ${SEL_CHECKOUT_BUTTON}

I Remove The First Cart Item
    Click    ${SEL_REMOVE_CART_ITEM_BTN} >> nth=0

I Click View Orders
    Click    ${SEL_VIEW_ORDERS_BUTTON}

# ── API request actions ────────────────────────────────────────────────────────

I Login Via API With Valid Credentials
    ${body}=    Create Dictionary    email=${VALID_EMAIL}    password=${VALID_PASSWORD}
    ${res}=     POST On Session      shopdemo    /login    json=${body}
    ...         expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}

I Login Via API With Invalid Credentials
    ${body}=    Create Dictionary    email=${INVALID_EMAIL}    password=${INVALID_PASSWORD}
    ${res}=     POST On Session      shopdemo    /login    json=${body}
    ...         expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}

I Request The Products List
    ${res}=    GET On Session    shopdemo    /products
    Set Test Variable    ${RESPONSE}    ${res}

I Add A Product To The Cart Via API
    [Arguments]    ${product_id}=1    ${quantity}=1
    ${body}=    Create Dictionary    productId=${product_id}    quantity=${quantity}
    ${res}=     POST On Session    shopdemo_auth    /cart/add    json=${body}
    Set Test Variable    ${RESPONSE}    ${res}

I Request The Cart Via API
    ${res}=    GET On Session    shopdemo_auth    /cart
    Set Test Variable    ${RESPONSE}    ${res}

I Submit The Checkout Via API
    ${res}=     POST On Session    shopdemo_auth    /checkout    expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}

I Submit The Checkout Via API With An Empty Cart
    # Attempt checkout without adding items first — expects 400
    ${res}=     POST On Session    shopdemo_auth    /checkout    expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}
