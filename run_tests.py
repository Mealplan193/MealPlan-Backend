"""Run every test suite and save the outcome to reports/test_results.txt.
    python run_tests.py
"""
import io
import sys
import unittest
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main() -> int:
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"), pattern="test_*.py", top_level_dir=str(ROOT))
    buf = io.StringIO()
    result = unittest.TextTestRunner(stream=buf, verbosity=2).run(suite)
    text = buf.getvalue()
    header = f"Meal Plan test run - {datetime.now():%Y-%m-%d %H:%M}\n" + "=" * 60 + "\n"
    summary = (f"\nSUMMARY: ran {result.testsRun}, failures {len(result.failures)}, errors {len(result.errors)}, "
               f"skipped {len(result.skipped)} -> {'ALL PASSED' if result.wasSuccessful() else 'FAILED'}\n")
    (ROOT / "reports").mkdir(exist_ok=True)
    (ROOT / "reports" / "test_results.txt").write_text(header + text + summary, encoding="utf-8")
    print(text + summary)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
