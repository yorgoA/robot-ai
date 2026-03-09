#!/usr/bin/env bash
# run_robot.sh
# ------------
# Wrapper that gives every Robot run its own timestamped folder so reports
# never overwrite each other.
#
# Usage:
#   ./scripts/run_robot.sh <test-file-or-folder> [extra robot args...]
#
# Examples:
#   ./scripts/run_robot.sh tests/web/dom_inspector_test.robot
#   ./scripts/run_robot.sh tests/debug/visual_debug_test.robot --variable PAGE_PATH:/catalog
#   ./scripts/run_robot.sh tests/web --include smoke
#   ./scripts/run_robot.sh tests/web/login_tests.robot --variable HEADLESS:false
#
# Output structure:
#   reports/
#   └── <suite-name>/
#       └── 2026-03-09_14-30-00/
#           ├── log.html
#           ├── report.html
#           └── output.xml

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <test-file-or-folder> [extra robot args...]"
  exit 1
fi

TARGET="$1"
shift

# Derive a clean suite name from the target path
SUITE_NAME=$(basename "$TARGET" .robot)

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_DIR="reports/${SUITE_NAME}/${TIMESTAMP}"

mkdir -p "$OUTPUT_DIR"

echo ""
echo "  Suite  : $TARGET"
echo "  Reports: $OUTPUT_DIR"
echo ""

robot \
  --outputdir "$OUTPUT_DIR" \
  --log       log.html      \
  --report    report.html   \
  --output    output.xml    \
  "$@"        \
  "$TARGET"

echo ""
echo "  Done. Open reports:"
echo "    $OUTPUT_DIR/report.html"
echo ""
