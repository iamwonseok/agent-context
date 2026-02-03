#!/usr/bin/env python3
"""
Fail if text files contain emoji or decorative symbols.

This script is intended to be used as a pre-commit hook to enforce the
repository policy:
- Emoji and decorative Unicode symbols are forbidden in all files
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    col: int
    codepoint: str
    char_repr: str


def is_forbidden_char(ch: str) -> bool:
    cp = ord(ch)

    # Variation selectors often appear in emoji sequences.
    if 0xFE00 <= cp <= 0xFE0F:
        return True

    # Zero width joiner used to compose emoji sequences.
    if cp == 0x200D:
        return True

    # Common emoji blocks.
    emoji_ranges = (
        (0x1F1E6, 0x1F1FF),  # flags
        (0x1F300, 0x1F5FF),
        (0x1F600, 0x1F64F),
        (0x1F680, 0x1F6FF),
        (0x1F700, 0x1F77F),
        (0x1F780, 0x1F7FF),
        (0x1F800, 0x1F8FF),
        (0x1F900, 0x1F9FF),
        (0x1FA00, 0x1FAFF),
        (0x2600, 0x26FF),  # Misc symbols (includes many emoji-style glyphs)
        (0x2700, 0x27BF),  # Dingbats (checkmarks, etc.)
    )
    for lo, hi in emoji_ranges:
        if lo <= cp <= hi:
            return True

    # Explicitly forbid common decorative symbols used in docs.
    forbidden_points = {
        0x2B50,  # WHITE MEDIUM STAR
        0x2605,  # BLACK STAR
        0x2606,  # WHITE STAR
        0x2713,  # CHECK MARK
        0x2714,  # HEAVY CHECK MARK
        0x2705,  # WHITE HEAVY CHECK MARK
    }
    return cp in forbidden_points


def scan_file(path: Path, max_findings: int = 20) -> list[Finding]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        # Text files should be UTF-8. If not, treat as failure with a clear message.
        return [
            Finding(
                path=str(path),
                line=1,
                col=1,
                codepoint="N/A",
                char_repr="non-utf8",
            )
        ]

    findings: list[Finding] = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        for col_no, ch in enumerate(line, start=1):
            if not is_forbidden_char(ch):
                continue
            findings.append(
                Finding(
                    path=str(path),
                    line=line_no,
                    col=col_no,
                    codepoint=f"U+{ord(ch):04X}",
                    char_repr=repr(ch),
                )
            )
            if len(findings) >= max_findings:
                return findings
    return findings


def main(argv: list[str]) -> int:
    paths = [Path(p) for p in argv[1:] if p]
    if not paths:
        return 0

    all_findings: list[Finding] = []
    for path in paths:
        if not path.exists():
            continue
        all_findings.extend(scan_file(path))

    if not all_findings:
        return 0

    print("[NG] Files contain forbidden emoji/symbols:", file=sys.stderr)
    for f in all_findings[:50]:
        print(
            f"{f.path}:{f.line}:{f.col}: {f.codepoint} {f.char_repr}",
            file=sys.stderr,
        )

    if len(all_findings) > 50:
        print(
            f"... and {len(all_findings) - 50} more occurrences",
            file=sys.stderr,
        )

    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

