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
Resource    ../locators/profile.resource
Resource    ../locators/orders.resource
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

I Enter Confirm Password "${password}"
    Type Text    ${SEL_CONFIRM_PASSWORD_INPUT}    ${password}    clear=True

I Click The Register Button
    Click    ${SEL_REGISTER_BUTTON}

I Register With Email "${email}" Password "${password}" And Confirm "${confirm}"
    I Enter Email "${email}"
    I Enter Password "${password}"
    I Enter Confirm Password "${confirm}"
    I Click The Register Button

# ── Catalog actions ────────────────────────────────────────────────────────────

I Add The First Product To My Cart
    Wait For Elements State     ${SEL_ADD_TO_CART_BTN} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}
    Click                       ${SEL_ADD_TO_CART_BTN} >> nth=0

I Set Quantity To "${qty}"
    Fill Text    ${SEL_QUANTITY_INPUT}    ${qty}

I Click The Cart Icon
    Click    ${SEL_NAV_CART}

# ── Product detail actions ─────────────────────────────────────────────────────

I Click The Add To Cart Button
    Wait For Elements State    ${SEL_ADD_TO_CART_BTN}    visible    timeout=${DEFAULT_TIMEOUT}
    Click                       ${SEL_ADD_TO_CART_BTN}

I Increase The Quantity
    Click    ${SEL_QUANTITY_INCREASE}

I Decrease The Quantity
    Click    ${SEL_QUANTITY_DECREASE}

# ── Profile actions ────────────────────────────────────────────────────────────

I Update My Profile Name To "${name}" And Address To "${address}"
    Fill Text    ${SEL_PROFILE_NAME_INPUT}       ${name}
    Fill Text    ${SEL_PROFILE_ADDRESS_INPUT}    ${address}
    Click        ${SEL_SAVE_PROFILE_BUTTON}

I Change My Password From "${current}" To "${new_password}" Confirming "${confirm}"
    Type Text    ${SEL_CURRENT_PASSWORD_INPUT}       ${current}        clear=True
    Type Text    ${SEL_NEW_PASSWORD_INPUT}           ${new_password}   clear=True
    Type Text    ${SEL_CONFIRM_NEW_PASSWORD_INPUT}   ${confirm}        clear=True
    Click         ${SEL_CHANGE_PASSWORD_BUTTON}

# ── Orders actions ─────────────────────────────────────────────────────────────

I Download The Receipt For The First Order
    ${promise}=    Promise To Wait For Download
    Click          ${SEL_DOWNLOAD_RECEIPT_BTN} >> nth=0
    ${download}=   Wait For    ${promise}
    Set Test Variable    ${DOWNLOAD}    ${download}

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
    ${res}=     POST On Session    shopdemo_auth    /cart/add    json=${body}    expected_status=any
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

I Remove A Product From The Cart Via API
    [Arguments]    ${product_id}
    ${body}=    Create Dictionary    productId=${product_id}
    ${res}=     POST On Session    shopdemo_auth    /cart/remove    json=${body}
    Set Test Variable    ${RESPONSE}    ${res}

I Update The Cart Quantity Via API
    [Arguments]    ${product_id}    ${quantity}
    ${body}=    Create Dictionary    productId=${product_id}    quantity=${quantity}
    ${res}=     POST On Session    shopdemo_auth    /cart/update    json=${body}    expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}

I Request My Profile Via API
    ${res}=    GET On Session    shopdemo_auth    /profile
    Set Test Variable    ${RESPONSE}    ${res}

I Update My Profile Via API
    [Arguments]    ${name}    ${email}    ${address}
    ${body}=    Create Dictionary    name=${name}    email=${email}    address=${address}
    ${res}=     PUT On Session    shopdemo_auth    /profile    json=${body}
    Set Test Variable    ${RESPONSE}    ${res}

I Change My Password Via API
    [Arguments]    ${current_password}    ${new_password}
    ${body}=    Create Dictionary    currentPassword=${current_password}    newPassword=${new_password}
    ${res}=     PUT On Session    shopdemo_auth    /profile/password    json=${body}    expected_status=any
    Set Test Variable    ${RESPONSE}    ${res}

I Request My Order History Via API
    ${res}=    GET On Session    shopdemo_auth    /orders
    Set Test Variable    ${RESPONSE}    ${res}
