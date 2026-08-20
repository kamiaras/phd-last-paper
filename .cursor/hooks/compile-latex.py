"""Compile fresh_rewrite.pdf after an edit to the manuscript or bibliography.

Skip when the latexmk watcher is already running (see watch-latex.ps1).
"""
from __future__ import annotations

import ctypes
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PID_FILE = ROOT / ".latexmk-watch.pid"
MIKTEX_BIN = (
    Path(os.environ.get("LOCALAPPDATA", ""))
    / "Programs"
    / "MiKTeX"
    / "miktex"
    / "bin"
    / "x64"
)
WATCH_MARKERS = ("fresh_rewrite.tex", "ref.bib")


def emit() -> None:
    sys.stdout.write("{}\n")
    sys.stdout.flush()


def pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        kernel32 = ctypes.windll.kernel32
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if handle:
            kernel32.CloseHandle(handle)
            return True
        return False
    try:
        os.kill(pid, 0)
        return True
    except PermissionError:
        return True
    except OSError:
        return False


def watch_running() -> bool:
    if not PID_FILE.exists():
        return False
    try:
        pid = int(PID_FILE.read_text(encoding="utf-8").strip())
    except ValueError:
        return False
    return pid_alive(pid)


def mentions_watched(raw: str) -> bool:
    blob = raw.lower().replace("\\", "/")
    return any(name in blob for name in WATCH_MARKERS)


def main() -> None:
    raw = sys.stdin.read()
    if raw.strip() and not mentions_watched(raw):
        emit()
        return
    if watch_running():
        emit()
        return

    env = os.environ.copy()
    if MIKTEX_BIN.is_dir():
        env["PATH"] = str(MIKTEX_BIN) + os.pathsep + env.get("PATH", "")

    try:
        subprocess.run(
            [
                "latexmk",
                "-pdf",
                "-interaction=nonstopmode",
                "-synctex=1",
                "-file-line-error",
                "fresh_rewrite.tex",
            ],
            cwd=str(ROOT),
            env=env,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass
    emit()


if __name__ == "__main__":
    main()
