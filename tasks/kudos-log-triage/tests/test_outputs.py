import os
from pathlib import Path


REPORT_PATH = Path("/workspace/reports/critical-access-report.txt")


def _parse_sections():
    assert REPORT_PATH.exists(), "critical-access-report.txt was not created in /workspace/reports"

    sections = {}
    current = None
    for raw_line in REPORT_PATH.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line.strip("[]")
            sections[current] = []
            continue
        assert current is not None, "Report contains data outside of a named section"
        sections[current].append(line)
    return sections


def test_expected_sections_present():
    sections = _parse_sections()
    assert set(sections) == {"external_admin_logins", "excessive_failed_logins"}


def test_external_admin_logins_section():
    sections = _parse_sections()
    expected = [
        "203.0.113.45|user=U402|timestamp=2024-12-01T10:12:33Z",
        "198.51.100.24|user=U509|timestamp=2024-12-01T12:43:11Z",
    ]
    assert sections["external_admin_logins"] == expected


def test_excessive_failed_logins_section():
    sections = _parse_sections()
    expected = [
        "U204|failed_attempts=3",
        "U305|failed_attempts=4",
    ]
    assert sections["excessive_failed_logins"] == expected
