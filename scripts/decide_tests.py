"""
decide_tests.py
---------------
Given parsed issue data (from parse_issue.py), outputs the Robot Framework
--include tag expression and test paths to use for a focused test run.

Usage:
    python scripts/parse_issue.py --repo owner/repo --issue 42 \
        | python scripts/decide_tests.py

Output (stdout, JSON):
    {
        "tags": "ui AND smoke",
        "paths": ["tests/ui"]
    }

TODO: Implement smarter tag/path selection based on issue body keywords,
      affected component metadata, and historical failure data.
"""

import json
import sys


AREA_TO_PATHS = {
    "ui": ["tests/ui"],
    "api": ["tests/api"],
    "e2e": ["tests/e2e"],
    "unknown": ["tests"],
}

AREA_TO_TAGS = {
    "ui": "ui",
    "api": "api",
    "e2e": "e2e",
    "unknown": "",
}


def main():
    raw = sys.stdin.read().strip()
    if not raw:
        print("[decide_tests] No input received on stdin.", file=sys.stderr)
        sys.exit(1)

    issue = json.loads(raw)
    area = issue.get("area", "unknown")

    result = {
        "tags": AREA_TO_TAGS.get(area, ""),
        "paths": AREA_TO_PATHS.get(area, ["tests"]),
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
