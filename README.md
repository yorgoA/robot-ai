# robot-ai

Robot Framework QA automation repository for the **ShopDemo** web application.
When connected to a CI pipeline, the suite becomes self-diagnosing. A GitHub Issue triggers `parse_issue.py`, which extracts the affected feature area and determines whether the problem is likely a UI issue, an API issue, or ambiguous. `decide_tests.py` then maps that to the right test layers, and if no existing test covers the reported scenario, `generate_test.py` creates one on the spot. The generated test always runs both layers when the cause is unclear: Playwright intercepts the network call made during the user action so the system can tell whether the API responded correctly or not. If the API was fine but the UI still misbehaved, OpenCV analyses the browser screenshot to detect visual anomalies. `comment_results.py` closes the loop by posting a layered diagnosis back to the issue, identifying a frontend fault, a backend fault, or a clean pass, without any manual intervention.

---

## Prerequisites

- Python 3.12+
- Node.js (required by Robot Framework Browser Library / Playwright)

---

## Install dependencies

```bash
pip install -r requirements.txt
rfbrowser init        # downloads Playwright browsers
```

---

## Configure base URLs

By default tests target local development servers:

| Variable        | Default                   |
|-----------------|---------------------------|
| `BASE_URL`      | `http://localhost:5173`   |
| `API_BASE_URL`  | `http://localhost:3000`   |


## Run UI tests

```bash
# All UI tests (headless)
robot --outputdir reports tests/ui

# Headed (useful for debugging)
robot --outputdir reports --variable HEADLESS:false tests/ui

# Smoke tests only
robot --outputdir reports --include smoke tests/ui
```

---

## Run API tests

```bash
robot --outputdir reports tests/api
```

---

## Run all tests

```bash
robot --outputdir reports --variable HEADLESS:true tests/
```

---

## View reports

After a run, open `reports/"name_of_test/report.html` in a browser.

---

## Project structure

```
Robot-mcp/
├── tests/
│   ├── web/
│   │   ├── auth/                    # Login / auth UI scenarios
│   │   ├── catalog/                 # Product catalog UI scenarios
│   │   ├── cart/                    # Cart & checkout UI scenarios
│   │   └── api/                     # REST API scenarios (auth, products, checkout)
│   └── debug/
│       └── visual_debug_test.robot  # OpenCV screenshot error detection
├── resources/
│   ├── keywords/                    # Atomic Given / When / Then keywords
│   ├── common_test_cases/           # Reusable multi-step flows
│   ├── locators/                    # Selectors + URL variables
│   └── variables.robot              # Global variables (URLs, credentials, timeouts)
├── selectors/                       # Raw data-testid / CSS selectors (source of truth)
├── external-keywords/
│   ├── AssertionKeywords.py         # BDD-style assertion library
│   ├── DOMInspectorKeywords.py      # Parses page HTML → selector recommendations
│   └── OpenCVDebugKeywords.py       # Visual error detection via OpenCV
├── scripts/
│   ├── TimestampedReportsListener.py  # Auto-organises reports/<suite>/<timestamp>/
│   ├── run_robot.sh                   # Shell wrapper for timestamped runs
│   ├── comment_results.py             # GitHub Issue workflow helpers
│   ├── decide_tests.py
│   ├── detect_coverage.py
│   └── parse_issue.py
├── data/
│   └── users.json                   # Test data
├── .github/
│   ├── workflows/                   # GitHub Actions CI pipelines
│   └── ISSUE_TEMPLATE/              # Bug report template
├── reports/                         # Robot Framework output (git-ignored)
├── requirements.txt
└── robot.yaml                       # Named task shortcuts (web-tests, api-tests, dom-inspect …)
```

---

## GitHub Issue–driven workflow (planned)

The `scripts/` directory contains four placeholder scripts that will power
an issue-driven test execution loop:

| Script                  | Purpose |
|-------------------------|---------|
| `parse_issue.py`        | Fetches a GitHub Issue and extracts area, labels, and description |
| `decide_tests.py`       | Maps issue data to Robot Framework tag/path selectors |
| `comment_results.py`    | Posts a pass/fail summary back to the issue as a comment |
| `detect_coverage.py`    | Scans test files and surfaces areas with no automated coverage |

**Planned flow:**

```
GitHub Issue opened / labelled
        │
        ▼
parse_issue.py  ──►  decide_tests.py  ──►  robot (targeted run)
                                                │
                                                ▼
                                      comment_results.py
                                      (posts results to issue)
```

To activate this workflow, set the `GITHUB_TOKEN` environment variable and
implement the `TODO` blocks in each script.

---

## Tags reference

| Tag          | Meaning |
|--------------|---------|
| `smoke`      | Fast, critical-path tests; run on every commit |
| `login`      | Login / auth tests |
| `catalog`    | Product listing tests |
| `cart`       | Shopping cart tests |
| `checkout`   | Checkout flow tests |
| `api`        | API-layer tests |
| `ui`         | Browser-based tests |
| `negative`   | Tests that verify error handling |
| `validation` | Input validation tests |
