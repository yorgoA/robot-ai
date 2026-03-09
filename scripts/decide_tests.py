"""
decide_tests.py
---------------
Given parsed issue data (from parse_issue.py), decides how to test it.

Strategy:
  1. Use suggested_layers to determine which test layers to run (UI, API, or both).
  2. Map the feature area to specific test tags and paths.
  3. If no existing test tags match the feature, set generate_custom_test=True
     so that generate_test.py is invoked before the run.

For ambiguous issues (UI action with possible backend cause), both layers are
scheduled. Network interception in the UI test will then reveal whether the
fault lies in the frontend or the API response.

Usage:
    python scripts/parse_issue.py --repo owner/repo --issue 42 \\
        | python scripts/decide_tests.py

Output (stdout, JSON):
    {
        "layers": ["ui", "api"],
        "ui_tags":  "cart",
        "ui_paths": ["tests/ui/cart"],
        "api_tags": "api AND cart",
        "api_paths": ["tests/api"],
        "generate_custom_test": false,
        "issue_context": { ... }   // forwarded for generate_test.py
    }
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

# Feature → UI test paths
FEATURE_UI_PATHS = {
    "login":    ["tests/web/auth"],
    "catalog":  ["tests/web/catalog"],
    "cart":     ["tests/web/cart"],
    "checkout": ["tests/web/cart"],
    "unknown":  ["tests/web"],
}

# Feature → UI tags
FEATURE_UI_TAGS = {
    "login":    "login",
    "catalog":  "catalog",
    "cart":     "cart",
    "checkout": "checkout",
    "unknown":  "ui",
}

# Feature → API tags (all API tests live under tests/api)
FEATURE_API_TAGS = {
    "login":    "api AND login",
    "catalog":  "api AND catalog",
    "cart":     "api AND cart",
    "checkout": "api AND checkout",
    "unknown":  "api",
}

API_PATHS = ["tests/api"]


def existing_tags(root: Path) -> set[str]:
    """Collect all [Tags] values across .robot files to check coverage."""
    import re
    tag_pattern = re.compile(r"\[Tags\]\s+(.+)")
    tags = set()
    for f in root.rglob("*.robot"):
        for match in tag_pattern.finditer(f.read_text(encoding="utf-8")):
            for tag in match.group(1).split():
                tags.add(tag.strip().lower())
    return tags


def main():
    raw = sys.stdin.read().strip()
    if not raw:
        print("[decide_tests] No input received on stdin.", file=sys.stderr)
        sys.exit(1)

    issue = json.loads(raw)
    feature         = issue.get("feature", "unknown")
    suggested_layers = issue.get("suggested_layers", ["ui", "api"])
    area            = issue.get("area", "unknown")

    known_tags = existing_tags(ROOT)

    ui_tag  = FEATURE_UI_TAGS.get(feature, "ui")
    api_tag = FEATURE_API_TAGS.get(feature, "api")

    # Check whether a matching test already exists for this feature
    feature_covered = feature != "unknown" and feature.lower() in known_tags
    generate_custom_test = not feature_covered

    result = {
        "layers":               suggested_layers,
        "ui_tags":              ui_tag  if "ui"  in suggested_layers else None,
        "ui_paths":             FEATURE_UI_PATHS.get(feature, ["tests/web"]) if "ui" in suggested_layers else None,
        "api_tags":             api_tag if "api" in suggested_layers else None,
        "api_paths":            API_PATHS if "api" in suggested_layers else None,
        "generate_custom_test": generate_custom_test,
        "issue_context":        issue,
    }

    if generate_custom_test:
        print(
            f"[decide_tests] No existing tests found for feature '{feature}'. "
            "generate_test.py will create a custom test.",
            file=sys.stderr,
        )

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
