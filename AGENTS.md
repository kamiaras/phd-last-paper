# Project context

## Goal

Fresh rewrite of the thesis chapter for publication.

## Source of truth

- **Active manuscript:** `fresh_rewrite.tex` — all editorial work goes here.

## Reference (read-only)

- **Baseline:** `Original/thesis-chapter-control.tex` — compare against this when rewriting.
- Do not edit files under `Original/` unless the user explicitly asks.

## Archive (recycle bin)

- **Path:** `archive/` — stale drafts, old copies, sent PDFs, and discarded variants.
- Do not edit, do not treat as the current manuscript, and do not copy from it into the rewrite unless the user asks to recover something specific.
- This folder is local-only and not tracked by git.

## Shared assets

- `ref.bib` — bibliography for the active rewrite.
- `images/` — figures used by the active rewrite.

## Commit convention

- `rewrite:` — manuscript changes to `fresh_rewrite.tex`, `ref.bib`, or `images/`.
- `chore:` — repo or meta changes (`.gitignore`, `AGENTS.md`, etc.).

## LaTeX

- Build artifacts are gitignored (`.aux`, `.log`, `.bbl`, etc.).
- Do not commit rebuildable PDF outputs from local builds (e.g. `fresh_rewrite.pdf`).
