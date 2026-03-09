"""
detect_coverage.py
------------------
Scans the project and prints:
  1. A keyword catalog grouped by role (Given / When / Then) — so QAs can
     check if a keyword already exists before writing a new one.
  2. Test coverage summary (which areas have test files).
  3. Tags found across all test suites.

Usage:
    python scripts/detect_coverage.py

TODO: Cross-reference discovered tags against a known feature map to
      identify areas with no automated coverage.
"""

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

TESTS_ROOT = ROOT / "tests/web"
TAG_PATTERN = re.compile(r"\[Tags\]\s+(.+)")
KEYWORD_DEF = re.compile(r"^([A-Z][^\n\[#].*\S)\s*$", re.MULTILINE)


def extract_keywords(path: Path) -> list[str]:
    """Return keyword names defined in a .resource or .robot file."""
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


def collect_tags(root: Path) -> list[str]:
    tags = set()
    for f in root.rglob("*.robot"):
        for match in TAG_PATTERN.finditer(f.read_text(encoding="utf-8")):
            for tag in match.group(1).split():
                tags.add(tag.strip())
    return sorted(tags)


def collect_test_files(root: Path) -> list[str]:
    return [f.name for f in root.rglob("*.robot")]


def main():
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
        for robot_file in sorted(directory.glob("*.robot")):
            keywords = extract_keywords(robot_file)
            for kw in keywords:
                print(f"   • {kw}")

    print("\n" + "=" * 60)
    print("  COVERAGE SUMMARY")
    print("=" * 60)
    test_files = collect_test_files(TESTS_ROOT)
    print(f"\n  Test files ({len(test_files)}):")
    for f in sorted(test_files):
        print(f"   • {f}")

    tags = collect_tags(TESTS_ROOT)
    print(f"\n  Tags in use: {', '.join(tags)}")
    print("\n  Gaps: TODO — cross-reference against feature map\n")


if __name__ == "__main__":
    main()
