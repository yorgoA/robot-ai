*** Settings ***
Documentation
...    GIVEN keywords — state setup, navigation, session initialisation.
...    A QA adding a new precondition keyword adds it HERE.
Library     Browser
Library     RequestsLibrary
Library     Collections
Library     ../../external-keywords/AssertionKeywords.py
Resource    ../locators/login.resource
Resource    ../locators/catalog.resource
Resource    ../locators/cart.resource
Resource    ../variables.robot


*** Keywords ***
# ── Browser ───────────────────────────────────────────────────────────────────

Open Browser To App
    ${args}=    Create List
    ...    --use-mock-keychain
    ...    --disable-features=AutofillAssistant,PasswordManagerOnboardingPromo
    ...    --disable-save-password-bubble
    New Browser    ${BROWSER}    headless=${HEADLESS}    args=${args}
    New Context    viewport={'width': 1280, 'height': 800}
    New Page       ${BASE_URL}
    Wait For Load State

Close Browser Session
    Close Browser

Take Screenshot On Failure
    Take Screenshot

Capture Step Start
    [Documentation]    Embeds a screenshot in the report before each step begins.
    Take Screenshot    filename=EMBED

# ── UI Navigation ──────────────────────────────────────────────────────────────

I Am On The Login Page
    Go To                       ${LOGIN_URL}
    Wait For Elements State     ${SEL_LOGIN_FORM}    visible    timeout=${DEFAULT_TIMEOUT}

I Am On The Register Page
    Go To                       ${REGISTER_URL}
    Wait For Elements State     ${SEL_EMAIL_INPUT}    visible    timeout=${DEFAULT_TIMEOUT}

I Am On The Product Catalog
    Go To                       ${CATALOG_URL}
    Wait For Elements State     ${SEL_PRODUCT_CARD} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}

I Navigate To My Cart
    Go To                       ${CART_URL}
    Wait For Elements State     ${SEL_CART_ITEM}    visible    timeout=${DEFAULT_TIMEOUT}

# ── API Session ────────────────────────────────────────────────────────────────

I Create An API Session
    Create Session    shopdemo    ${API_BASE_URL}    headers=${API_HEADERS}    verify=True

I Am Authenticated To The API
    I Create An API Session
    ${body}=    Create Dictionary    email=${VALID_EMAIL}    password=${VALID_PASSWORD}
    ${res}=     POST On Session      shopdemo    /login    json=${body}
    The Response Status Is    ${res}    200
    ${token}=           Set Variable    ${res.json()}[token]
    ${auth_headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Accept=application/json
    ...    Authorization=Bearer ${token}
    Create Session    shopdemo_auth    ${API_BASE_URL}    headers=${auth_headers}    verify=True
