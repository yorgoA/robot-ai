*** Settings ***
Documentation    DOM Inspector — navigates to ${BASE_URL}${PAGE_PATH} and lists every
...              identifiable element with its recommended selector strategy.
...
...              ┌─ HOW TO USE ─────────────────────────────────────────────┐
...              │ 1. Change ${PAGE_PATH} below to the path you want to     │
...              │    inspect: /  /login  /catalog  /cart  etc.             │
...              │ 2. Run:  robot tests/web/dom_inspector_test.robot        │
...              │    or use: ./scripts/run_robot.sh tests/web/dom_inspector_test.robot │
...              │ 3. Check reports/ for dom_report_<timestamp>.json        │
...              └──────────────────────────────────────────────────────────┘
Library          Browser
Library          ../../external-keywords/DOMInspectorKeywords.py
Resource         ../../resources/variables.robot

*** Variables ***
# ── TARGET PAGE ──────────────────────────────────────────────────────────────
# Change this to any route you want to inspect:  /   /login   /catalog   /cart
${PAGE_PATH}    /login

*** Test Cases ***
Inspect DOM Elements On Page
    [Documentation]    Opens ${BASE_URL}${PAGE_PATH}, captures the rendered HTML,
    ...                and logs every identifiable element with its best selector.
    [Tags]    dom    inspector    debug
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Page       ${BASE_URL}${PAGE_PATH}
    ${html}=       Get Page Source
    ${elements}=   Inspect Dom Elements
    ...    html=${html}
    ...    page_url=${BASE_URL}${PAGE_PATH}
    Log    \nFound ${elements.__len__()} identifiable elements on ${BASE_URL}${PAGE_PATH}    console=True
    [Teardown]    Close Browser
