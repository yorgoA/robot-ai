"""
triage_issue.py
----------------
End-to-end orchestrator for the issue-driven test pipeline. This is what
.github/workflows/issue-triage.yml runs. It ties together the same logic the
individual scripts expose (parse_issue, decide_tests, generate_test,
comment_results) as direct function calls rather than a shell pipe, so one
process can make the run/skip decision below.

Two outcomes, depending on whether the reported feature already has coverage:

  * Coverage exists  -> run the real, existing tests for that feature and post
                         a genuine pass/fail diagnosis. Fully automatic.
  * No coverage yet  -> generate a starter test (see generate_test.py) and post
                         a comment saying so, rather than running it. A freshly
                         generated test has no real assertions yet (they're
                         TODOs for a human/AI to fill in) - running it would
                         trivially "pass" and report a false clean bill of
                         health, which is worse than not running it at all.

Usage:
    python scripts/triage_issue.py --repo owner/repo --issue 42
"""

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import comment_results
import decide_tests
import generate_test
from parse_issue import detect_area_and_layers, detect_feature, fetch_issue

ROOT = Path(__file__).parent.parent


def post_or_preview(repo: str, issue_number: int, comment: str):
    """Posts the comment, or prints a preview if GITHUB_TOKEN isn't set (local runs)."""
    try:
        comment_results.post_comment(repo, issue_number, comment)
    except RuntimeError as exc:
        print(f"[triage] {exc}", file=sys.stderr)
        print("\n--- Preview of comment that would be posted ---")
        print(comment)


def parse_args():
    parser = argparse.ArgumentParser(description="Run the full issue-driven test pipeline.")
    parser.add_argument("--repo", required=True, help="GitHub repo in owner/repo format")
    parser.add_argument("--issue", required=True, type=int, help="Issue number")
    return parser.parse_args()


def build_plan(issue: dict) -> dict:
    """Same decision logic as decide_tests.py, inlined so it can be called directly."""
    feature = issue["feature"]
    layers = issue["suggested_layers"]

    known_tags = decide_tests.existing_tags(ROOT)
    feature_covered = feature != "unknown" and feature.lower() in known_tags

    return {
        "layers": layers,
        "ui_tags": decide_tests.FEATURE_UI_TAGS.get(feature, "ui") if "ui" in layers else None,
        "ui_paths": decide_tests.FEATURE_UI_PATHS.get(feature, ["tests/web"]) if "ui" in layers else None,
        "api_tags": decide_tests.FEATURE_API_TAGS.get(feature, "api") if "api" in layers else None,
        "api_paths": decide_tests.API_PATHS if "api" in layers else None,
        "generate_custom_test": not feature_covered,
    }


def run_layer(out_dir: Path, tags: str | None, paths: list[str]) -> dict:
    cmd = ["robot", "--outputdir", str(out_dir)]
    if tags:
        cmd += ["--include", tags]
    cmd += paths
    subprocess.run(cmd, cwd=ROOT, check=False)
    return comment_results.parse_output_xml(str(out_dir / "output.xml"))


def main():
    args = parse_args()

    # 1. Parse
    fetched = fetch_issue(args.repo, args.issue)
    area, layers, ambiguity_reason = detect_area_and_layers(fetched["labels"], fetched["title"], fetched["body"])
    feature = detect_feature(fetched["labels"], fetched["title"], fetched["body"])
    issue = {
        "issue_number": args.issue,
        "title": fetched["title"],
        "body": fetched["body"],
        "labels": fetched["labels"],
        "area": area,
        "feature": feature,
        "suggested_layers": layers,
        "ambiguity_reason": ambiguity_reason,
    }
    print(f"[triage] area={area} feature={feature} layers={layers}", file=sys.stderr)

    # 2. Decide
    plan = build_plan(issue)

    # 3a. No existing coverage -> generate a starter test and stop; don't run it (see docstring).
    if plan["generate_custom_test"]:
        generate_test.OUT_DIR.mkdir(parents=True, exist_ok=True)
        generated = []
        if "ui" in layers:
            path = generate_test.OUT_DIR / f"issue_{args.issue}_{feature}_ui.robot"
            path.write_text(generate_test.build_ui_test(issue, feature), encoding="utf-8")
            generated.append(str(path.relative_to(ROOT)))
        if "api" in layers:
            path = generate_test.OUT_DIR / f"issue_{args.issue}_{feature}_api.robot"
            path.write_text(generate_test.build_api_test(issue, feature), encoding="utf-8")
            generated.append(str(path.relative_to(ROOT)))

        comment = (
            f"## 🧪 Automated QA Report (Issue #{args.issue})\n\n"
            f"No existing tests cover the **{feature}** feature area, so I generated a starting "
            f"point instead of a diagnosis:\n\n"
            + "\n".join(f"- `{f}`" for f in generated)
            + "\n\nThese still need the reported steps and assertions filled in (see the `TODO` "
            "markers) before they can run automatically. Once merged, this issue will be "
            "diagnosed automatically on the next run.\n\n_Automated report generated by robot-ai._"
        )
        post_or_preview(args.repo, args.issue, comment)
        print(f"[triage] Generated {len(generated)} starter test(s) and notified issue #{args.issue}.", file=sys.stderr)
        return

    # 3b. Coverage exists -> run the real tests and diagnose for real.
    ui_stats = None
    api_stats = None

    if "ui" in layers:
        ui_stats = run_layer(ROOT / "reports" / f"issue_{args.issue}_ui", plan["ui_tags"], plan["ui_paths"])

    if "api" in layers:
        api_stats = run_layer(ROOT / "reports" / f"issue_{args.issue}_api", plan["api_tags"], plan["api_paths"])

    comment = comment_results.build_comment(args.issue, ui_stats, api_stats, None)
    post_or_preview(args.repo, args.issue, comment)
    print(f"[triage] Posted diagnosis to issue #{args.issue}.", file=sys.stderr)


if __name__ == "__main__":
    main()
