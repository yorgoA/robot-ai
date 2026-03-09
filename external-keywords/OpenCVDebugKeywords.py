"""
OpenCVDebugKeywords.py
----------------------
Visual-error analysis of screenshots using OpenCV.

Detects:
  - Red regions      → error messages / form validation highlights
  - Orange regions   → warnings / toast notifications
  - Dark-bordered boxes → modal dialogs / alert containers

Saves an annotated PNG alongside the findings and returns a summary dict.

Usage in .robot files:
    Library    ../../external-keywords/OpenCVDebugKeywords.py
"""

import json
import os
from datetime import datetime

import cv2
import numpy as np
from robot.api import logger
from robot.api.deco import keyword


class OpenCVDebugKeywords:
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_DOC_FORMAT = "reST"

    @keyword
    def analyze_screenshot_for_errors(
        self,
        screenshot_path: str,
        output_dir: str = "reports",
        min_area: int = 150,
    ) -> dict:
        """
        Analyze *screenshot_path* with OpenCV and return a findings summary.

        Returns a dict with keys:
        ``source``, ``total_findings``, ``error_regions``, ``warning_regions``,
        ``bordered_boxes``, ``annotated_image``, ``findings``.

        An annotated PNG with bounding-box overlays is written to *output_dir*.
        """
        if not os.path.exists(screenshot_path):
            raise FileNotFoundError(f"Screenshot not found: {screenshot_path}")

        image = cv2.imread(screenshot_path)
        if image is None:
            raise ValueError(f"Could not read image: {screenshot_path}")

        hsv      = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        annotated = image.copy()
        findings  = []

        # --- red regions (errors) ---
        mask_red = cv2.bitwise_or(
            cv2.inRange(hsv, np.array([0,   100, 80]),  np.array([10,  255, 255])),
            cv2.inRange(hsv, np.array([160, 100, 80]),  np.array([180, 255, 255])),
        )
        findings += self._regions_from_mask(mask_red, "error", min_area, annotated, (0, 0, 220))

        # --- orange/yellow regions (warnings) ---
        mask_warn = cv2.inRange(hsv, np.array([10, 100, 100]), np.array([35, 255, 255]))
        findings += self._regions_from_mask(mask_warn, "warning", min_area, annotated, (0, 140, 255))

        # --- dark-bordered boxes (modals / dialogs) ---
        gray   = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        edges  = cv2.Canny(gray, 80, 200)
        cnts, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in cnts:
            area = cv2.contourArea(cnt)
            if area < 2000:
                continue
            x, y, w, h = cv2.boundingRect(cnt)
            if not (0.3 < w / max(h, 1) < 5.0):
                continue
            findings.append({"type": "bordered_box", "bbox": [x, y, w, h], "area": int(area)})
            cv2.rectangle(annotated, (x, y), (x + w, y + h), (200, 160, 0), 1)

        # --- save annotated image ---
        os.makedirs(output_dir, exist_ok=True)
        ts             = datetime.now().strftime("%Y%m%d_%H%M%S")
        annotated_path = os.path.join(output_dir, f"opencv_debug_{ts}.png")
        cv2.imwrite(annotated_path, annotated)

        summary = {
            "source":          screenshot_path,
            "total_findings":  len(findings),
            "error_regions":   sum(1 for f in findings if f["type"] == "error"),
            "warning_regions": sum(1 for f in findings if f["type"] == "warning"),
            "bordered_boxes":  sum(1 for f in findings if f["type"] == "bordered_box"),
            "annotated_image": annotated_path,
            "findings":        findings,
        }
        self._log_summary(summary)
        return summary

    @keyword
    def compare_screenshots_for_diff(
        self,
        baseline_path: str,
        current_path: str,
        output_dir: str = "reports",
        diff_threshold: float = 30.0,
    ) -> dict:
        """
        Compare *baseline_path* against *current_path* and highlight pixel differences.

        Returns a dict with ``diff_score`` (mean absolute difference, 0–255),
        ``diff_pixels``, ``annotated_image``, and ``passed`` (True if diff_score
        is below *diff_threshold*).
        """
        for p in (baseline_path, current_path):
            if not os.path.exists(p):
                raise FileNotFoundError(f"Image not found: {p}")

        base = cv2.imread(baseline_path)
        curr = cv2.imread(current_path)

        if base.shape != curr.shape:
            curr = cv2.resize(curr, (base.shape[1], base.shape[0]))

        diff       = cv2.absdiff(base, curr)
        gray_diff  = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
        _, thresh  = cv2.threshold(gray_diff, 25, 255, cv2.THRESH_BINARY)
        diff_pixels = int(np.count_nonzero(thresh))
        diff_score  = float(np.mean(gray_diff))

        annotated = curr.copy()
        cnts, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in cnts:
            if cv2.contourArea(cnt) > 50:
                x, y, w, h = cv2.boundingRect(cnt)
                cv2.rectangle(annotated, (x, y), (x + w, y + h), (0, 0, 255), 2)

        os.makedirs(output_dir, exist_ok=True)
        ts             = datetime.now().strftime("%Y%m%d_%H%M%S")
        annotated_path = os.path.join(output_dir, f"diff_debug_{ts}.png")
        cv2.imwrite(annotated_path, annotated)

        result = {
            "baseline":        baseline_path,
            "current":         current_path,
            "diff_score":      round(diff_score, 2),
            "diff_pixels":     diff_pixels,
            "annotated_image": annotated_path,
            "passed":          diff_score < float(diff_threshold),
        }
        lines = [
            "",
            "=" * 55,
            "OPENCV DIFF REPORT",
            "=" * 55,
            f"  Baseline      : {baseline_path}",
            f"  Current       : {current_path}",
            f"  Diff score    : {result['diff_score']} (threshold {diff_threshold})",
            f"  Diff pixels   : {diff_pixels}",
            f"  Result        : {'PASS' if result['passed'] else 'FAIL'}",
            f"  Annotated     : {annotated_path}",
            "=" * 55,
            "",
        ]
        report = "\n".join(lines)
        logger.info(report)
        logger.console(report)
        return result

    # ------------------------------------------------------------------
    def _regions_from_mask(self, mask, label, min_area, annotated, color):
        kernel  = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
        cleaned = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
        cnts, _ = cv2.findContours(cleaned, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        results = []
        for cnt in cnts:
            area = cv2.contourArea(cnt)
            if area < min_area:
                continue
            x, y, w, h = cv2.boundingRect(cnt)
            results.append({"type": label, "bbox": [x, y, w, h], "area": int(area)})
            cv2.rectangle(annotated, (x, y), (x + w, y + h), color, 2)
            cv2.putText(
                annotated, label.upper(),
                (x, max(y - 5, 12)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1,
            )
        return results

    def _log_summary(self, summary: dict) -> None:
        lines = [
            "",
            "=" * 60,
            f"OPENCV VISUAL DEBUG — {os.path.basename(summary['source'])}",
            "=" * 60,
            f"  Error regions   : {summary['error_regions']}",
            f"  Warning regions : {summary['warning_regions']}",
            f"  Bordered boxes  : {summary['bordered_boxes']}",
            f"  Total findings  : {summary['total_findings']}",
            f"  Annotated image : {summary['annotated_image']}",
            "=" * 60,
            "",
        ]
        report = "\n".join(lines)
        logger.info(report)
        logger.console(report)
