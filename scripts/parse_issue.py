"""
parse_issue.py
--------------
Fetches a GitHub Issue by number and extracts structured information
that drives targeted, layered test execution.

Usage:
    python scripts/parse_issue.py --repo owner/repo --issue 42

Output (stdout, JSON):
    {
        "issue_number": 42,
        "title": "...",
        "body": "...",
        "labels": ["bug", "cart"],
        "area": "ui" | "api" | "ambiguous" | "unknown",
        "feature": "cart" | "login" | "catalog" | "checkout" | "unknown",
        "suggested_layers": ["ui"] | ["api"] | ["ui", "api"],
        "ambiguity_reason": "..." | null
    }

Environment variables:
    GITHUB_TOKEN  - Personal access token with repo read access.
"""

import argparse
import json
import os
import sys


def parse_args():
    parser = argparse.ArgumentParser(description="Parse a GitHub Issue for QA routing.")
    parser.add_argument("--repo", required=True, help="GitHub repo in owner/repo format")
    parser.add_argument("--issue", required=True, type=int, help="Issue number")
    return parser.parse_args()


# Keywords that strongly signal a specific layer
_API_KEYWORDS = {"api", "endpoint", "backend", "request", "response", "server", "status code", "payload", "json"}
_UI_KEYWORDS  = {"button", "form", "page", "browser", "click", "display", "image", "render", "layout", "visible", "modal", "dropdown", "input"}

# Keywords that signal a specific feature area
_FEATURE_MAP = {
    "login":    {"login", "logout", "sign in", "sign out", "auth", "password", "token", "session"},
    "catalog":  {"product", "listing", "catalog", "search", "filter", "sort", "item"},
    "cart":     {"cart", "basket", "add to cart", "remove", "quantity"},
    "checkout": {"checkout", "payment", "order", "purchase", "billing", "shipping", "confirm"},
}


def detect_area_and_layers(labels: list[str], title: str, body: str) -> tuple[str, list[str], str | None]:
    """
    Returns (area, suggested_layers, ambiguity_reason).

    - If only API signals  → ("api",       ["api"],       None)
    - If only UI signals   → ("ui",        ["ui"],        None)
    - If both signals      → ("ambiguous", ["ui", "api"], reason)
    - If neither           → ("unknown",   ["ui", "api"], reason)

    Ambiguous means the issue describes a UI action but we cannot rule out
    a backend cause without running both layers.
    """
    text = " ".join([title, body] + labels).lower()

    api_hits = [kw for kw in _API_KEYWORDS if kw in text]
    ui_hits  = [kw for kw in _UI_KEYWORDS  if kw in text]

    if api_hits and not ui_hits:
        return "api", ["api"], None

    if ui_hits and not api_hits:
        return "ui", ["ui"], None

    if ui_hits and api_hits:
        reason = (
            f"Issue mentions UI actions ({', '.join(ui_hits[:3])}) and "
            f"possible backend signals ({', '.join(api_hits[:3])}). "
            "Both layers will be tested; network interception will determine the fault side."
        )
        return "ambiguous", ["ui", "api"], reason

    # Neither clear signal — run everything and let the test diagnose
    reason = "No clear UI or API signals found in the issue. Running both layers as a precaution."
    return "unknown", ["ui", "api"], reason


def detect_feature(labels: list[str], title: str, body: str) -> str:
    text = " ".join([title, body] + labels).lower()
    for feature, keywords in _FEATURE_MAP.items():
        if any(kw in text for kw in keywords):
            return feature
    return "unknown"


def fetch_issue(repo: str, issue_number: int) -> dict:
    # TODO: Replace stub with real GitHub API call using PyGithub.
    # from github import Github
    # g = Github(os.environ["GITHUB_TOKEN"])
    # issue = g.get_repo(repo).get_issue(issue_number)
    # return {"title": issue.title, "body": issue.body or "", "labels": [l.name for l in issue.labels]}
    raise NotImplementedError("GitHub integration not yet implemented. Set GITHUB_TOKEN and uncomment PyGithub code.")


def main():
    args = parse_args()

    try:
        data = fetch_issue(args.repo, args.issue)
    except NotImplementedError as exc:
        print(f"[parse_issue] {exc}", file=sys.stderr)
        sys.exit(1)

    area, suggested_layers, ambiguity_reason = detect_area_and_layers(
        data["labels"], data["title"], data["body"]
    )
    feature = detect_feature(data["labels"], data["title"], data["body"])

    result = {
        "issue_number":    args.issue,
        "title":           data["title"],
        "body":            data["body"],
        "labels":          data["labels"],
        "area":            area,
        "feature":         feature,
        "suggested_layers": suggested_layers,
        "ambiguity_reason": ambiguity_reason,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
