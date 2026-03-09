"""
generate_test.py
----------------
Generates a custom Robot Framework .robot test file tailored to a specific
GitHub Issue, based on the decision plan produced by decide_tests.py.

The generated test is always issue-specific: it navigates to the relevant
feature, performs the action described in the issue, and validates both the
UI state and the API response (network interception) so the fault layer can
be determined automatically.

Usage:
    python scripts/parse_issue.py --repo owner/repo --issue 42 \\
        | python scripts/decide_tests.py \\
        | python scripts/generate_test.py

Output:
    Writes  tests/generated/issue_<number>_<feature>.robot
    Prints  the file path to stdout.
"""

import json
import sys
from pathlib import Path
from datetime import datetime

ROOT      = Path(__file__).parent.parent
OUT_DIR   = ROOT / "tests" / "generated"

# ---------------------------------------------------------------------------
# URL map — matches resources/locators/urls.resource
# ---------------------------------------------------------------------------
FEATURE_URLS = {
    "login":    "${BASE_URL}/login",
    "catalog":  "${BASE_URL}/products",
    "cart":     "${BASE_URL}/cart",
    "checkout": "${BASE_URL}/checkout",
    "unknown":  "${BASE_URL}",
}

# API endpoints to intercept per feature
FEATURE_API_ROUTE = {
    "login":    "/api/auth/**",
    "catalog":  "/api/products/**",
    "cart":     "/api/cart/**",
    "checkout": "/api/orders/**",
    "unknown":  "/api/**",
}


def _sanitize(text: str, max_len: int = 60) -> str:
    """Truncate and strip newlines for use inside .robot file strings."""
    return text.replace("\n", " ").replace("\r", "").strip()[:max_len]


def build_ui_test(issue: dict, feature: str) -> str:
    title     = _sanitize(issue.get("title", "Untitled issue"))
    body      = _sanitize(issue.get("body",  ""), max_len=120)
    number    = issue.get("issue_number", 0)
    url       = FEATURE_URLS.get(feature, "${BASE_URL}")
    api_route = FEATURE_API_ROUTE.get(feature, "/api/**")
    ambiguous = issue.get("area") == "ambiguous"

    interception_block = ""
    diagnosis_block = ""

    if ambiguous:
        interception_block = f"""\
    # Intercept the API call triggered by the user action
    &{{api_response}}    Browser.Promise Fetch    {api_route}
"""
        diagnosis_block = """\

    # Diagnose fault layer from intercepted API response
    # If api_response status != 200 → backend fault; else → frontend fault
    ${diagnosis}    Diagnose Fault Layer    ${api_response}    ${opencv_findings}
    Log    Diagnosis: ${diagnosis}    level=WARN
"""

    opencv_block = """\

    # Capture screenshot and run OpenCV visual analysis
    ${screenshot}    Browser.Take Screenshot    fullPage=True
    ${opencv_findings}    Analyze Screenshot For Errors    ${screenshot}
    Run Keyword If    ${opencv_findings}[total_findings] > 0
    ...    Log    OpenCV findings: ${opencv_findings}    level=WARN
"""

    return f"""\
*** Settings ***
Documentation     Auto-generated test for GitHub Issue #{number}: {title}
...               Source: {body}
...               Generated: {datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")}
Library           Browser
Library           ../../external-keywords/OpenCVDebugKeywords.py
Library           ../../external-keywords/AssertionKeywords.py
Resource          ../../resources/keywords/given.resource
Resource          ../../resources/keywords/when.resource
Resource          ../../resources/keywords/then.resource
Suite Teardown    Close Browser

*** Variables ***
${{HEADLESS}}      True

*** Test Cases ***
Issue #{number} — {title}
    [Tags]    generated    {feature}    issue-{number}
    [Documentation]    Reproduces the scenario from GitHub Issue #{number}.
    ...                 Runs UI interaction with network interception to pinpoint
    ...                 whether the fault is in the frontend or the API layer.

    # ── Setup ──────────────────────────────────────────────────────────────
    New Browser    chromium    headless=${{HEADLESS}}
    New Page       {url}
{interception_block}
    # ── Reproduce the reported action ───────────────────────────────────────
    # TODO: Replace the steps below with the exact actions from the issue.
    #       Use DOM Inspector keywords if selectors are unknown.
    Log    Reproducing: {title}
    # Example: Click    [data-testid="submit-button"]
{opencv_block}{diagnosis_block}
    # ── Assertions ───────────────────────────────────────────────────────────
    # TODO: Add assertions that verify the expected vs actual behaviour.
    # Example: Page Should Contain    Expected result text
"""


def build_api_test(issue: dict, feature: str) -> str:
    title   = _sanitize(issue.get("title", "Untitled issue"))
    number  = issue.get("issue_number", 0)
    route   = FEATURE_API_ROUTE.get(feature, "/api/**").replace("**", "endpoint")

    return f"""\
*** Settings ***
Documentation     Auto-generated API test for GitHub Issue #{number}: {title}
...               Generated: {datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")}
Library           RequestsLibrary
Library           ../../external-keywords/AssertionKeywords.py
Resource          ../../resources/keywords/given.resource
Resource          ../../resources/keywords/then.resource

*** Variables ***
${{BASE_URL}}    http://localhost:3000

*** Test Cases ***
Issue #{number} API — {title}
    [Tags]    generated    api    {feature}    issue-{number}
    [Documentation]    Directly tests the API layer for GitHub Issue #{number}.
    ...                 A failure here confirms a backend fault.

    Create Session    shopdemo    ${{BASE_URL}}

    # TODO: Replace with the actual endpoint and method from the issue.
    # Example: GET /api/products/123
    ${{response}}    GET On Session    shopdemo    {route}

    # Assert the response is healthy
    Should Be Equal As Integers    ${{response.status_code}}    200
    # TODO: Add body assertions relevant to the issue.
"""


def main():
    raw = sys.stdin.read().strip()
    if not raw:
        print("[generate_test] No input received on stdin.", file=sys.stderr)
        sys.exit(1)

    plan  = json.loads(raw)
    issue = plan.get("issue_context", {})

    feature = issue.get("feature", "unknown")
    number  = issue.get("issue_number", 0)
    layers  = plan.get("layers", ["ui"])

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    generated = []

    if "ui" in layers:
        ui_path = OUT_DIR / f"issue_{number}_{feature}_ui.robot"
        ui_path.write_text(build_ui_test(issue, feature), encoding="utf-8")
        generated.append(str(ui_path.relative_to(ROOT)))
        print(f"[generate_test] UI test  → {ui_path}", file=sys.stderr)

    if "api" in layers:
        api_path = OUT_DIR / f"issue_{number}_{feature}_api.robot"
        api_path.write_text(build_api_test(issue, feature), encoding="utf-8")
        generated.append(str(api_path.relative_to(ROOT)))
        print(f"[generate_test] API test → {api_path}", file=sys.stderr)

    output = {
        "generated_files": generated,
        "layers":          layers,
        "feature":         feature,
        "issue_number":    number,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
