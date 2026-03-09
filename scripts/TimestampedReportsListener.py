"""
TimestampedReportsListener.py
------------------------------
Robot Framework listener (API v2) that moves every run's output files
into   reports/<suite-name>/<YYYY-MM-DD_HH-MM-SS>/   after the run ends.

This means repeated runs never overwrite each other.

Attach via:   --listener scripts/TimestampedReportsListener.py
(robot.yaml already adds this to every task automatically)
"""

import os
import shutil
from datetime import datetime


class TimestampedReportsListener:
    ROBOT_LISTENER_API_VERSION = 2

    def __init__(self, base_dir="reports"):
        self.base_dir = base_dir
        self.suite_name = None

    def start_suite(self, name, attrs):
        if attrs.get("id") == "s1":
            safe = name.lower().replace(" ", "_").replace("/", "_")
            self.suite_name = safe

    def close(self):
        ts   = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        dest = os.path.join(self.base_dir, self.suite_name or "run", ts)
        os.makedirs(dest, exist_ok=True)

        moved = []

        # standard Robot output files
        for fname in ("output.xml", "log.html", "report.html"):
            src = os.path.join(self.base_dir, fname)
            if os.path.exists(src):
                shutil.move(src, os.path.join(dest, fname))
                moved.append(fname)

        # screenshots and debug images sitting directly in base_dir
        for fname in os.listdir(self.base_dir):
            if fname.lower().endswith((".png", ".jpg", ".jpeg")):
                shutil.move(
                    os.path.join(self.base_dir, fname),
                    os.path.join(dest, fname),
                )
                moved.append(fname)

        if moved:
            print(f"\n  Reports → {dest}/")
            report = os.path.join(dest, "report.html")
            if os.path.exists(report):
                os.system(f"open '{report}'")
