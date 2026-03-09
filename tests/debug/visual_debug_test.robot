*** Settings ***
Documentation    Visual Debug — uses OpenCV to detect error regions, warnings,
...              and alert boxes in a screenshot.
...
...              ┌─ HOW TO USE ─────────────────────────────────────────────┐
...              │ Mode A — analyze an existing screenshot:                 │
...              │   Set ${SCREENSHOT_PATH} to the file path and run.       │
...              │                                                          │
...              │ Mode B — capture a fresh screenshot first:               │
...              │   Leave ${SCREENSHOT_PATH} as NONE and set ${PAGE_PATH}. │
...              │   The test opens the page, takes a screenshot, then      │
...              │   analyzes it automatically.                             │
...              │                                                          │
...              │ Optional: set ${BASELINE_PATH} to compare against a      │
...              │   known-good baseline (pixel-diff mode).                 │
...              └──────────────────────────────────────────────────────────┘
Library          Browser
Library          ../../external-keywords/OpenCVDebugKeywords.py
Resource         ../../resources/variables.robot

*** Variables ***
# ── INPUTS ───────────────────────────────────────────────────────────────────
# Path to an existing screenshot. Set to NONE to capture one from PAGE_PATH.
${SCREENSHOT_PATH}    NONE
# Used only when SCREENSHOT_PATH is NONE:
${PAGE_PATH}          /login
# Optional: path to a baseline image for pixel-diff comparison. Set to NONE to skip.
${BASELINE_PATH}      NONE

*** Test Cases ***
Analyze Screenshot For Visual Errors
    [Documentation]    Loads (or captures) a screenshot and runs OpenCV error detection.
    ...                Annotated output image is saved to reports/.
    [Tags]    visual    debug    opencv
    ${path}=    Resolve Screenshot Path
    ${results}=    Analyze Screenshot For Errors    ${path}
    Log    \nTotal findings: ${results}[total_findings]    console=True
    Log    Annotated image: ${results}[annotated_image]    console=True

Compare Screenshot Against Baseline
    [Documentation]    Pixel-diff between ${BASELINE_PATH} and a current screenshot.
    ...                Skipped automatically when BASELINE_PATH is NONE.
    [Tags]    visual    debug    diff    baseline
    Skip If    '${BASELINE_PATH}' == 'NONE'    No baseline set — skipping diff test
    ${path}=    Resolve Screenshot Path
    ${result}=    Compare Screenshots For Diff    ${BASELINE_PATH}    ${path}
    Log    Diff score: ${result}[diff_score]    console=True
    Should Be True    ${result}[passed]
    ...    msg=Screenshot differs from baseline (score ${result}[diff_score])

*** Keywords ***
Resolve Screenshot Path
    [Documentation]    Returns SCREENSHOT_PATH if set, otherwise captures a fresh
    ...                screenshot of BASE_URL+PAGE_PATH and returns that path.
    IF    '${SCREENSHOT_PATH}' != 'NONE'
        RETURN    ${SCREENSHOT_PATH}
    END
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Page       ${BASE_URL}${PAGE_PATH}
    ${captured}=    Take Screenshot
    Close Browser
    RETURN    ${captured}
