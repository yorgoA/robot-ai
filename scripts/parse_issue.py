"""
parse_issue.py
--------------
Fetches a GitHub Issue by number and extracts structured information
that can be used to drive targeted test execution.

Usage:
    python scripts/parse_issue.py --repo owner/repo --issue 42

Output (stdout, JSON):
    {
        "issue_number": 42,
        "title": "...",
        "body": "...",
        "labels": ["bug", "ui"],
        "area": "ui" | "api" | "e2e" | "unknown"
    }

Environment variables:
    GITHUB_TOKEN  - Personal access token with repo read access.

TODO: Implement full parsing logic when GitHub Issue workflow is activated.
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


def detect_area(labels: list[str], title: str, body: str) -> str:
    """Heuristically determine which test area an issue belongs to."""
    text = (title + " " + body + " " + " ".join(labels)).lower()
    if any(kw in text for kw in ["api", "endpoint", "backend", "request", "response"]):
        return "api"
    if any(kw in text for kw in ["ui", "page", "button", "form", "browser", "click"]):
        return "ui"
    if any(kw in text for kw in ["e2e", "end-to-end", "flow", "journey"]):
        return "e2e"
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

    area = detect_area(data["labels"], data["title"], data["body"])
    result = {
        "issue_number": args.issue,
        "title": data["title"],
        "body": data["body"],
        "labels": data["labels"],
        "area": area,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
