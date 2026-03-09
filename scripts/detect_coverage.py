"""
detect_coverage.py
------------------
Scans the project and reports:
  1. Keyword catalog grouped by role (Given / When / Then).
  2. Test coverage summary per feature area.
  3. Tags found across all test suites.
  4. Coverage gaps — feature areas with no test files or tags.

The --json flag outputs a machine-readable summary consumed by decide_tests.py
to determine whether a custom test needs to be generated for an issue.

Usage:
    python scripts/detect_coverage.py           # human-readable
    python scripts/detect_coverage.py --json    # JSON for pipeline use
"""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent

KEYWORD_FILES = {
    "GIVEN  (setup / navigation)": ROOT / "resources/keywords/given.resource",
    "WHEN   (actions)":            ROOT / "resources/keywords/when.resource",
    "THEN   (assertions)":         ROOT / "resources/keywords/then.resource",
}

COMPOSITE_DIRS = {
    "GIVEN composite flows": ROOT / "resources/common_test_cases/given",
    "WHEN  composite flows": ROOT / "resources/common_test_cases/when",
    "THEN  composite flows": ROOT / "resources/common_test_cases/then",
}

TESTS_ROOT = ROOT / "tests"
TAG_PATTERN = re.compile(r"\[Tags\]\s+(.+)")

# Canonical feature areas the system knows about
KNOWN_FEATURES = ["login", "catalog", "cart", "checkout"]


def extract_keywords(path: Path) -> list[str]:
    if not path.exists():
        return []
    in_keywords_section = False
    keywords = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() == "*** Keywords ***":
            in_keywords_section = True
            continue
        if line.startswith("***") and in_keywords_section:
            break
        if in_keywords_section and line and not line.startswith(" ") and not line.startswith("#"):
            keywords.append(line.strip())
    return keywords


def collect_tags(root: Path) -> set[str]:
    tags: set[str] = set()
    for f in root.rglob("*.robot"):
        for match in TAG_PATTERN.finditer(f.read_text(encoding="utf-8")):
            for tag in match.group(1).split():
                tags.add(tag.strip().lower())
    return tags


def collect_test_files_by_feature(root: Path) -> dict[str, list[str]]:
    """Group test .robot files by feature area based on their directory path."""
    result: dict[str, list[str]] = {f: [] for f in KNOWN_FEATURES}
    result["other"] = []
    for f in root.rglob("*.robot"):
        parts = f.parts
        matched = False
        for feature in KNOWN_FEATURES:
            if feature in parts or feature in str(f).lower():
                result[feature].append(f.name)
                matched = True
                break
        if not matched:
            result["other"].append(f.name)
    return result


def compute_gaps(tags: set[str], files_by_feature: dict) -> list[str]:
    gaps = []
    for feature in KNOWN_FEATURES:
        has_tag   = feature in tags
        has_files = bool(files_by_feature.get(feature))
        if not has_tag and not has_files:
            gaps.append(feature)
    return gaps


def parse_args():
    parser = argparse.ArgumentParser(description="Detect QA test coverage.")
    parser.add_argument("--json", action="store_true", help="Output machine-readable JSON")
    return parser.parse_args()


def main():
    args = parse_args()

    tags             = collect_tags(TESTS_ROOT)
    files_by_feature = collect_test_files_by_feature(TESTS_ROOT)
    gaps             = compute_gaps(tags, files_by_feature)

    if args.json:
        output = {
            "tags":             sorted(tags),
            "files_by_feature": files_by_feature,
            "gaps":             gaps,
            "covered_features": [f for f in KNOWN_FEATURES if f not in gaps],
        }
        print(json.dumps(output, indent=2))
        return

    # Human-readable output
    print("=" * 60)
    print("  KEYWORD CATALOG  — check here before writing a new keyword")
    print("=" * 60)

    for label, path in KEYWORD_FILES.items():
        keywords = extract_keywords(path)
        print(f"\n── {label} ({path.name}) ──")
        for kw in keywords:
            print(f"   • {kw}")

    print("\n" + "=" * 60)
    print("  COMPOSITE FLOWS  — reusable multi-step sequences")
    print("=" * 60)

    for label, directory in COMPOSITE_DIRS.items():
        print(f"\n── {label} ──")
        if not directory.exists():
            print("   (directory not found)")
            continue
        for robot_file in sorted(directory.glob("*.robot")):
            for kw in extract_keywords(robot_file):
                print(f"   • {kw}")

    print("\n" + "=" * 60)
    print("  COVERAGE BY FEATURE")
    print("=" * 60)
    for feature in KNOWN_FEATURES:
        files  = files_by_feature.get(feature, [])
        tagged = feature in tags
        status = "✓" if (files or tagged) else "✗ GAP"
        print(f"\n  [{status}] {feature.upper()}")
        for f in sorted(files):
            print(f"         • {f}")
        if tagged and not files:
            print(f"         (tagged only — no dedicated test file)")

    print("\n" + "=" * 60)
    print("  GAPS — features with no tests")
    print("=" * 60)
    if gaps:
        for g in gaps:
            print(f"   ✗ {g}")
    else:
        print("   All known features are covered.")

    print(f"\n  All tags in use: {', '.join(sorted(tags))}\n")


if __name__ == "__main__":
    main()
