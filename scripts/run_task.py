"""
run_task.py
-----------
Runs a named task defined in robot.yaml.

Usage:
    python scripts/run_task.py <task-name> [-- extra robot args...]
    python scripts/run_task.py --list

Examples:
    python scripts/run_task.py smoke
    python scripts/run_task.py dev -- --variable HEADLESS:false
"""

import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).parent.parent
CONFIG_PATH = ROOT / "robot.yaml"


def load_tasks() -> dict:
    with open(CONFIG_PATH, encoding="utf-8") as f:
        config = yaml.safe_load(f)
    return config.get("tasks", {})


def main():
    tasks = load_tasks()

    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        print("Available tasks:", ", ".join(tasks))
        sys.exit(0 if len(sys.argv) >= 2 else 1)

    if sys.argv[1] == "--list":
        for name in tasks:
            print(name)
        return

    task_name = sys.argv[1]
    extra_args = sys.argv[2:]
    if extra_args and extra_args[0] == "--":
        extra_args = extra_args[1:]

    if task_name not in tasks:
        print(f"[run_task] Unknown task '{task_name}'. Available: {', '.join(tasks)}", file=sys.stderr)
        sys.exit(1)

    task = tasks[task_name]
    command = [task["command"], *task.get("args", []), *extra_args]

    print(f"$ {' '.join(command)}")
    result = subprocess.run(command, cwd=ROOT)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
