*** Settings ***
Documentation
...    THEN keywords — assertions and outcome verification.
...    A QA adding a new assertion keyword adds it HERE.
Library     Browser
Library     ../../external-keywords/AssertionKeywords.py
Resource    ../locators/login.resource
Resource    ../locators/catalog.resource
Resource    ../locators/cart.resource
Resource    ../locators/profile.resource
Resource    ../locators/orders.resource
Resource    ../variables.robot


*** Variables ***
# Populated at runtime by Set Test Variable inside when.resource request keywords.
${RESPONSE}    ${NONE}


*** Keywords ***
# ── Login assertions ───────────────────────────────────────────────────────────

I Should Be Logged In
    Wait For Elements State    ${SEL_NAVBAR_USER}    visible    timeout=${DEFAULT_TIMEOUT}

I Should See A Login Error
    Wait For Elements State    ${SEL_LOGIN_ERROR}    visible    timeout=${DEFAULT_TIMEOUT}
    ${text}=    Get Text        ${SEL_LOGIN_ERROR}
    The Text Is Not Empty       ${text}

I Should Be On The Login Page
    Wait For Elements State    ${SEL_LOGIN_FORM}    visible    timeout=${DEFAULT_TIMEOUT}

I Should Not Be Logged In
    Wait For Elements State    ${SEL_NAVBAR_USER}    hidden    timeout=${DEFAULT_TIMEOUT}

I Should See A Register Error
    Wait For Elements State    ${SEL_REGISTER_ERROR}    visible    timeout=${DEFAULT_TIMEOUT}
    ${text}=    Get Text        ${SEL_REGISTER_ERROR}
    The Text Is Not Empty       ${text}

I Should See Register Error Containing "${expected}"
    I Should See A Register Error
    ${text}=    Get Text    ${SEL_REGISTER_ERROR}
    Should Contain    ${text}    ${expected}

I Should Be On The Register Page
    Wait For Elements State    ${SEL_REGISTER_FORM}    visible    timeout=${DEFAULT_TIMEOUT}

# ── Catalog assertions ─────────────────────────────────────────────────────────

The Catalog Should Show Products
    Wait For Elements State     ${SEL_PRODUCT_CARD} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}
    ${count}=    Get Element Count    ${SEL_PRODUCT_CARD}
    The Count Is Greater Than   ${count}    0

The Cart Badge Should Show "${expected}"
    Wait For Elements State     ${SEL_CART_BADGE}    visible    timeout=${DEFAULT_TIMEOUT}
    ${count}=    Get Text        ${SEL_CART_BADGE}
    The Number Is Equal To      ${count}    ${expected}

# ── Product detail assertions ──────────────────────────────────────────────────

The Product Detail Page Should Show "${name}"
    Wait For Elements State    ${SEL_PRODUCT_DETAIL_NAME}    visible    timeout=${DEFAULT_TIMEOUT}
    ${text}=    Get Text        ${SEL_PRODUCT_DETAIL_NAME}
    Should Be Equal As Strings    ${text}    ${name}

The Quantity Field Should Show "${expected}"
    ${value}=    Get Property    ${SEL_QUANTITY_INPUT}    value
    Should Be Equal As Strings    ${value}    ${expected}

I Should See The Add To Cart Feedback
    Wait For Elements State    ${SEL_ADD_TO_CART_FEEDBACK}    visible    timeout=${DEFAULT_TIMEOUT}

# ── Cart / Checkout assertions ─────────────────────────────────────────────────

My Cart Should Have Items
    ${count}=    Get Element Count    ${SEL_CART_ITEM}
    The Count Is Greater Than   ${count}    0

The Order Should Be Confirmed
    Wait For Elements State     ${SEL_ORDER_SUCCESS}    visible    timeout=${DEFAULT_TIMEOUT}

The Order ID Should Be Displayed
    Wait For Elements State     ${SEL_ORDER_ID}    visible    timeout=${DEFAULT_TIMEOUT}
    ${text}=    Get Text         ${SEL_ORDER_ID}
    The Text Is Not Empty        ${text}

# ── Profile assertions ─────────────────────────────────────────────────────────

My Profile Should Show Email "${email}"
    Wait For Elements State    ${SEL_PROFILE_EMAIL_INPUT}    visible    timeout=${DEFAULT_TIMEOUT}
    ${value}=    Get Property    ${SEL_PROFILE_EMAIL_INPUT}    value
    Should Be Equal As Strings    ${value}    ${email}

I Should See A Profile Success Message
    Wait For Elements State    ${SEL_PROFILE_SUCCESS}    visible    timeout=${DEFAULT_TIMEOUT}

I Should See A Password Success Message
    Wait For Elements State    ${SEL_PASSWORD_SUCCESS}    visible    timeout=${DEFAULT_TIMEOUT}

I Should See A Password Error
    Wait For Elements State    ${SEL_PASSWORD_ERROR}    visible    timeout=${DEFAULT_TIMEOUT}
    ${text}=    Get Text        ${SEL_PASSWORD_ERROR}
    The Text Is Not Empty       ${text}

# ── Orders assertions ──────────────────────────────────────────────────────────

I Should See The Empty Orders State
    Wait For Elements State    ${SEL_EMPTY_ORDERS}    visible    timeout=${DEFAULT_TIMEOUT}

My Order History Should Contain "${count}" Order
    Wait For Elements State    ${SEL_ORDER_CARD} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}
    ${actual}=    Get Element Count    ${SEL_ORDER_CARD}
    The Number Is Equal To    ${actual}    ${count}

The Downloaded Receipt Should Be Named "${pattern}"
    Should Match    ${DOWNLOAD}[suggestedFilename]    ${pattern}

# ── API assertions (operate on ${RESPONSE} set by a When keyword) ──────────────

The Response Status Should Be "${code}"
    The Response Status Is    ${RESPONSE}    ${code}

The Response Should Contain Key "${key}"
    The Response Contains Key    ${RESPONSE}    ${key}

The Response Body Should Be A List
    The Response Body Is A List    ${RESPONSE}

The Response Body Should Not Be Empty
    ${body}=    Set Variable    ${RESPONSE.json()}
    The List Is Not Empty    ${body}

Each Product Should Have Field "${field}"
    ${body}=    Set Variable    ${RESPONSE.json()}
    Each Item Has Field    ${body}    ${field}
