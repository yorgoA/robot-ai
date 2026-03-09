"""
DOMInspectorKeywords.py
-----------------------
Parses a rendered HTML page source and returns every identifiable element
with its recommended Robot Framework / Browser-library selector strategy.

Priority order: data-testid > id > name > role > class > tag

Usage in .robot files:
    Library    ../../external-keywords/DOMInspectorKeywords.py
"""

import json
import os
from datetime import datetime

from bs4 import BeautifulSoup
from robot.api import logger
from robot.api.deco import keyword

_STRATEGY_PRIORITY = {"data-testid": 1, "id": 2, "name": 3, "role": 4, "class": 5, "tag": 6}

_INTERACTIVE_TAGS = {
    "input", "button", "a", "select", "textarea",
    "form", "label", "option", "details", "summary",
}


def _best_selector(tag: str, attrs: dict) -> tuple[str, str]:
    """Return (selector_string, strategy_name) for a BeautifulSoup tag."""
    testid = (attrs.get("data-testid") or "").strip()
    el_id  = (attrs.get("id")          or "").strip()
    name   = (attrs.get("name")        or "").strip()
    role   = (attrs.get("role")        or "").strip()
    classes = [c for c in (attrs.get("class") or []) if c.strip()]

    if testid:  return f'[data-testid="{testid}"]',  "data-testid"
    if el_id:   return f"#{el_id}",                   "id"
    if name:    return f'[name="{name}"]',             "name"
    if role:    return f'[role="{role}"]',             "role"
    if classes: return f".{classes[0]}",               "class"
    return tag,                                         "tag"


class DOMInspectorKeywords:
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_DOC_FORMAT = "reST"

    @keyword
    def inspect_dom_elements(
        self,
        html: str,
        page_url: str = "",
        output_dir: str = "reports",
    ) -> list:
        """
        Parse *html* and return every identifiable element as a list of dicts.

        Each dict contains:
        ``tag``, ``id``, ``test_id``, ``name``, ``role``, ``aria_label``,
        ``type``, ``classes``, ``selector``, ``strategy``.

        Writes ``dom_report_<timestamp>.json`` to *output_dir* and logs a
        formatted table to the Robot Framework log.
        """
        soup = BeautifulSoup(html, "html.parser")
        elements = []

        for el in soup.find_all(True):
            tag  = el.name
            attrs = el.attrs if el.attrs else {}

            testid  = (attrs.get("data-testid") or "").strip() or None
            el_id   = (attrs.get("id")          or "").strip() or None
            role    = (attrs.get("role")        or "").strip() or None
            name    = (attrs.get("name")        or "").strip() or None
            aria    = (attrs.get("aria-label")  or "").strip() or None
            el_type = (attrs.get("type")        or "").strip() or None
            classes = [c for c in (attrs.get("class") or []) if c.strip()]

            is_interactive = tag in _INTERACTIVE_TAGS
            is_identifiable = testid or el_id or role

            if not is_interactive and not is_identifiable:
                continue

            selector, strategy = _best_selector(tag, attrs)

            elements.append({
                "tag":       tag,
                "id":        el_id,
                "test_id":   testid,
                "name":      name,
                "role":      role,
                "aria_label": aria,
                "type":      el_type,
                "classes":   classes[:4],
                "selector":  selector,
                "strategy":  strategy,
            })

        elements.sort(key=lambda e: _STRATEGY_PRIORITY.get(e["strategy"], 99))

        self._log_table(elements, page_url)
        self._save_json(elements, page_url, output_dir)
        return elements

    # ------------------------------------------------------------------
    def _log_table(self, elements: list, page_url: str) -> None:
        W_TAG, W_SEL, W_STRAT, W_EXTRA = 10, 52, 12, 34
        sep    = f"{'─'*W_TAG}─{'─'*W_SEL}─{'─'*W_STRAT}─{'─'*W_EXTRA}"
        header = (
            f"{'TAG':<{W_TAG}} {'SELECTOR':<{W_SEL}} "
            f"{'STRATEGY':<{W_STRAT}} {'name / role / type / aria':<{W_EXTRA}}"
        )
        title = f"DOM INSPECTION — {len(elements)} elements  [{page_url}]"
        lines = ["", "=" * len(sep), title, "=" * len(sep), header, sep]

        for el in elements:
            extra = "  ".join(
                p for p in [
                    f"name={el['name']}"      if el["name"]      else "",
                    f"role={el['role']}"      if el["role"]      else "",
                    f"type={el['type']}"      if el["type"]      else "",
                    f"aria={el['aria_label']}" if el["aria_label"] else "",
                ] if p
            )[:W_EXTRA]
            lines.append(
                f"{el['tag']:<{W_TAG}} {el['selector']:<{W_SEL}} "
                f"{el['strategy']:<{W_STRAT}} {extra:<{W_EXTRA}}"
            )

        lines += [sep, ""]
        logger.info("\n".join(lines))
        logger.console(f"\n  DOM Inspector: {len(elements)} elements on {page_url}")

    def _save_json(self, elements: list, page_url: str, output_dir: str) -> None:
        os.makedirs(output_dir, exist_ok=True)
        ts   = datetime.now().strftime("%Y%m%d_%H%M%S")
        path = os.path.join(output_dir, f"dom_report_{ts}.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump({"url": page_url, "count": len(elements), "elements": elements}, fh, indent=2)
        logger.info(f"DOM report saved → {path}")
        logger.console(f"  DOM report saved: {path}")
