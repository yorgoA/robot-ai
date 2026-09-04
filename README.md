# robot-ai

Robot Framework QA automation repository for the **ShopDemo** web application, with an
issue-driven pipeline layered on top: open a GitHub Issue, and it gets triaged and tested
automatically.

`parse_issue.py` reads the issue title/body/labels and classifies it — which feature area,
and whether it's likely a UI issue, an API issue, or ambiguous between the two. `decide_tests.py`
maps that to the matching test tags. From there, one of two things happens:

- **The feature already has test coverage** — the matching tests run for real, and
  `comment_results.py` posts a genuine pass/fail diagnosis back to the issue (frontend fault,
  backend fault, or clean pass), no manual step required.
- **Nothing covers that feature yet** — `generate_test.py` scaffolds a starting test (UI and/or
  API, depending on the issue) instead of guessing at a result. A freshly generated test has no
  real assertions yet, so running it would just report a false "all clear"; the bot says as much
  and asks for the reproduction steps to be filled in, then diagnoses it automatically on the
  next run.

`scripts/triage_issue.py` is what actually wires this together end to end, and
`.github/workflows/issue-triage.yml` runs it whenever an issue is opened or labelled. Locally,
`scripts/detect_coverage.py` shows the same coverage picture that `decide_tests.py` uses to
make that call.

---

## Prerequisites

- Python 3.12+
- Node.js (required by Robot Framework Browser Library / Playwright)
- The **ShopDemo** application must be running locally. Clone and start it before running any tests:

```bash
git clone https://github.com/yorgoA/ShopDemo.git
cd ShopDemo
npm install
npm run dev
```

| Service  | URL                   |
|----------|-----------------------|
| Frontend | http://localhost:5173 |
| Backend  | http://localhost:3000 |

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


## Run tests

The easiest way is via the named tasks in [`robot.yaml`](robot.yaml):

```bash
python scripts/run_task.py --list          # see what's available
python scripts/run_task.py smoke           # fast, critical-path tests
python scripts/run_task.py web-tests       # all UI tests
python scripts/run_task.py api-tests       # all API tests
python scripts/run_task.py all-tests       # everything except debug/inspector tools
python scripts/run_task.py dev             # headed, against localhost, for local debugging
```

Every task also accepts extra `robot` arguments after `--`, e.g.
`python scripts/run_task.py web-tests -- --include login`.

Equivalent plain `robot` commands, if you'd rather not go through the task runner
(all UI and API suites live under `tests/web/`, split by tag):

```bash
# All tests (headless)
robot --outputdir reports --exclude debug tests/web

# Headed
robot --outputdir reports --variable HEADLESS:false --exclude debug tests/web

# Smoke tests only
robot --outputdir reports --include smoke tests/web

# API layer only
robot --outputdir reports --include api tests/web
```

---

## View reports

After a run, open `reports/"name_of_test/report.html` in a browser.

---

## Project structure

```
robot-ai/
├── tests/
│   ├── web/
│   │   ├── auth/                    # Login / auth UI scenarios
│   │   ├── catalog/                 # Product catalog UI scenarios
│   │   ├── cart/                    # Cart & checkout UI scenarios
│   │   ├── api/                     # REST API scenarios (auth, products, checkout)
│   │   └── dom_inspector_test.robot # Selector-recommendation debug tool (tagged `debug`)
│   ├── debug/
│   │   └── visual_debug_test.robot  # OpenCV screenshot error detection (tagged `debug`)
│   └── generated/                   # Issue-driven scaffolds from generate_test.py (git-ignored)
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
│   ├── run_task.py                    # Runs a named task from robot.yaml
│   ├── triage_issue.py                # End-to-end issue pipeline (see below)
│   ├── parse_issue.py
│   ├── decide_tests.py
│   ├── generate_test.py
│   ├── comment_results.py
│   └── detect_coverage.py
├── data/
│   └── users.json                   # Test data
├── .github/
│   ├── workflows/                   # CI (push/PR) + the issue-triage pipeline
│   └── ISSUE_TEMPLATE/              # Bug report template
├── reports/                         # Robot Framework output (git-ignored)
├── requirements.txt
└── robot.yaml                       # Named task definitions, run via scripts/run_task.py
```

---

## GitHub Issue–driven workflow

```
GitHub Issue opened / labelled
        │
        ▼
parse_issue.py  ──►  decide_tests.py
                          │
              ┌───────────┴───────────┐
        covered already          nothing covers it
              │                       │
              ▼                       ▼
      robot (targeted run)     generate_test.py
              │                 (scaffolds a test,
              ▼                  asks for the repro
     comment_results.py          steps, stops there)
   (posts a real diagnosis)
```

`scripts/triage_issue.py` runs this whole thing as one process — it's what
[`.github/workflows/issue-triage.yml`](.github/workflows/issue-triage.yml) invokes whenever an
issue is opened or labelled, using the repo's own `GITHUB_TOKEN` (no personal token needed for
same-repo issues). Run it locally against a real issue with:

```bash
GITHUB_TOKEN=<a token with repo read/write> \
  python scripts/triage_issue.py --repo owner/repo --issue 42
```

Without `GITHUB_TOKEN` set, or without write access, it still runs the tests and prints the
comment it would have posted instead of failing outright.

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
