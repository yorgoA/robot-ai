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
Resource    ../locators/profile.resource
Resource    ../locators/orders.resource
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

I Am On My Profile Page
    Go To                       ${PROFILE_URL}
    Wait For Elements State     ${SEL_PROFILE_FORM}    visible    timeout=${DEFAULT_TIMEOUT}

I Am On My Orders Page
    [Documentation]    Navigates to Orders and waits for either the order list or the
    ...                empty-state to render (a CSS selector list, so it matches whichever
    ...                the account actually has).
    Go To    ${ORDERS_URL}
    Wait For Elements State     ${SEL_ORDERS_LIST}, ${SEL_EMPTY_ORDERS}    visible    timeout=${DEFAULT_TIMEOUT}

I Am On The First Product's Detail Page
    I Am On The Product Catalog
    Click    ${SEL_PRODUCT_NAME_LINK} >> nth=0
    Wait For Elements State     ${SEL_PRODUCT_DETAIL_PAGE}    visible    timeout=${DEFAULT_TIMEOUT}

# ── API Session ────────────────────────────────────────────────────────────────

I Create An API Session
    Create Session    shopdemo    ${API_BASE_URL}    headers=${API_HEADERS}    verify=True

I Am Authenticated To The API
    Ensure The Test Account Exists
    ${body}=    Create Dictionary    email=${VALID_EMAIL}    password=${VALID_PASSWORD}
    ${res}=     POST On Session      shopdemo    /login    json=${body}
    The Response Status Is    ${res}    200
    ${token}=           Set Variable    ${res.json()}[token]
    ${auth_headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Accept=application/json
    ...    Authorization=Bearer ${token}
    Create Session    shopdemo_auth    ${API_BASE_URL}    headers=${auth_headers}    verify=True

I Register A Unique Account And Log In
    [Documentation]    Registers a brand-new account (via the API, for speed) and injects the
    ...                resulting session into the browser instead of driving the register form.
    ...                Also sets up the "shopdemo_auth" API session (same one
    ...                `I Am Authenticated To The API` creates), so cart/checkout/profile API
    ...                keywords work immediately without a second login.
    ...                Suites that need an isolated account - profile edits, password changes,
    ...                order history that must start empty - use this instead of the shared
    ...                VALID_EMAIL account, so they never affect (or get affected by) each other.
    [Arguments]    ${email}    ${password}=${VALID_PASSWORD}
    I Create An API Session
    ${body}=    Create Dictionary    email=${email}    password=${password}
    ${res}=     POST On Session    shopdemo    /register    json=${body}
    The Response Status Is    ${res}    201
    ${token}=      Set Variable    ${res.json()}[token]
    ${user_id}=    Set Variable    ${res.json()}[user][id]
    ${user_json}=  Evaluate    json.dumps({"id": $user_id, "email": $email})    json

    ${auth_headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Accept=application/json
    ...    Authorization=Bearer ${token}
    Create Session    shopdemo_auth    ${API_BASE_URL}    headers=${auth_headers}    verify=True

    New Page    ${BASE_URL}
    LocalStorage Set Item    token    ${token}
    LocalStorage Set Item    user     ${user_json}
    Reload
    Wait For Elements State    ${SEL_NAVBAR_USER}    visible    timeout=${DEFAULT_TIMEOUT}

I Register A Unique API Test Account
    [Documentation]    Same as `I Register A Unique Account And Log In` but for pure-API
    ...                suites that never open a browser - registers via the API and sets up
    ...                the "shopdemo_auth" session, nothing more.
    [Arguments]    ${email}    ${password}=Test123!
    I Create An API Session
    ${body}=    Create Dictionary    email=${email}    password=${password}
    ${res}=     POST On Session    shopdemo    /register    json=${body}
    The Response Status Is    ${res}    201
    ${token}=    Set Variable    ${res.json()}[token]
    ${auth_headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Accept=application/json
    ...    Authorization=Bearer ${token}
    Create Session    shopdemo_auth    ${API_BASE_URL}    headers=${auth_headers}    verify=True

Ensure The Test Account Exists
    [Documentation]    Registers the shared QA test account via the API if it doesn't already
    ...                exist yet. Safe to call from any suite in any order - this makes the
    ...                whole framework runnable against a freshly-seeded ShopDemo instance with
    ...                no manual account setup. A 409 (already registered) is the expected
    ...                steady state once the account has been created once.
    I Create An API Session
    ${body}=    Create Dictionary    email=${VALID_EMAIL}    password=${VALID_PASSWORD}
    ${res}=     POST On Session    shopdemo    /register    json=${body}    expected_status=any
    IF    ${res.status_code} not in [201, 409]
        Fail    Could not prepare the shared test account (HTTP ${res.status_code}): ${res.text}
    END
