#!/usr/bin/env python3
"""
Check/fix trailing whitespace (spaces/tabs at end-of-line).

Default behavior:
- Excludes Markdown files (*.md) because trailing spaces can be meaningful.
- Skips binary files.
- If no files are provided, scans tracked + untracked (non-ignored) files via git.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator, Sequence


TRAILING_RE = re.compile(r"[ \t]+(?=(\r?\n)?$)")


@dataclass(frozen=True)
class Result:
    file: Path
    changed_lines: int


def _run_git(args: Sequence[str]) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL)


def git_candidate_files() -> list[Path]:
    files: list[Path] = []
    for git_args in (["ls-files", "-z"], ["ls-files", "-z", "--others", "--exclude-standard"]):
        out = _run_git(git_args)
        for raw in out.split(b"\0"):
            if not raw:
                continue
            # Paths from git are repo-relative
            files.append(Path(raw.decode("utf-8", errors="surrogateescape")))
    return files


def is_binary(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            chunk = f.read(8192)
        return b"\0" in chunk
    except OSError:
        return True


def iter_existing_files(files: Iterable[Path]) -> Iterator[Path]:
    for f in files:
        p = Path(f)
        if p.is_file():
            yield p


def should_exclude(path: Path, exclude_exts: set[str]) -> bool:
    ext = path.suffix.lower().lstrip(".")
    return ext in exclude_exts


def check_or_fix_file(path: Path, fix: bool) -> Result | None:
    if is_binary(path):
        return None

    try:
        original = path.read_text(encoding="utf-8", errors="surrogateescape", newline="")
    except OSError:
        return None

    lines = original.splitlines(keepends=True)
    changed = 0
    new_lines: list[str] = []

    for line in lines:
        new_line = TRAILING_RE.sub("", line)
        if new_line != line:
            changed += 1
        new_lines.append(new_line)

    if changed == 0:
        return None

    if fix:
        try:
            path.write_text("".join(new_lines), encoding="utf-8", errors="surrogateescape", newline="")
        except OSError:
            return None

    return Result(file=path, changed_lines=changed)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Check only (default)")
    mode.add_argument("--fix", action="store_true", help="Fix in-place")
    p.add_argument(
        "--exclude-ext",
        action="append",
        default=["md"],
        help="Exclude files with this extension (default: md). Can be repeated.",
    )
    p.add_argument(
        "--stdin",
        action="store_true",
        help="Read newline-separated file paths from stdin (in addition to positional args).",
    )
    p.add_argument("files", nargs="*", help="Files to check/fix (repo-relative or absolute)")
    return p.parse_args(list(argv))


def _normalize_paths(items: Iterable[str]) -> list[Path]:
    paths: list[Path] = []
    for s in items:
        if not s:
            continue
        p = Path(s)
        if p.is_absolute():
            try:
                p = p.relative_to(Path.cwd())
            except ValueError:
                # Outside repo/cwd; keep absolute
                pass
        paths.append(p)
    return paths


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    fix = bool(args.fix)

    exclude_exts = {e.lower().lstrip(".") for e in args.exclude_ext}

    candidates: list[Path] = []
    candidates.extend(_normalize_paths(args.files))

    if args.stdin:
        candidates.extend(_normalize_paths(line.strip() for line in sys.stdin.read().splitlines()))

    if not candidates:
        try:
            candidates = git_candidate_files()
        except Exception:
            print("[ERROR] git not available; please pass file paths explicitly.", file=sys.stderr)
            return 2

    results: list[Result] = []
    for path in iter_existing_files(candidates):
        if should_exclude(path, exclude_exts):
            continue
        r = check_or_fix_file(path, fix=fix)
        if r is not None:
            results.append(r)

    if results:
        for r in results:
            print(f"{r.file}: {r.changed_lines} line(s)")

    if fix:
        return 0

    return 1 if results else 0


if __name__ == "__main__":
    os.chdir(Path.cwd())
    raise SystemExit(main(sys.argv[1:]))

