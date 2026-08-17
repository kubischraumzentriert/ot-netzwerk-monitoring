---
title: "AGENTS"
output: "html"
---

# AGENTS.md

This repository uses this file as the primary instruction and context entry
point for Codex and other coding agents.

Before starting substantive work in this repository:

1. Read `README.md`.
2. Read `SECURITY.md` and follow it strictly.
3. Read `Statusanker.md` for the current project state.
4. Read the relevant workflow docs, especially `docs/06_betriebsmanual_workflow.md`.
5. Follow the repository rules for documentation, Git usage, verification, and
   reporting.
6. Ensure every new `.md` document starts with a YAML header and set
   `output: "html"` there unless a different output format is explicitly needed.

## Working rules

- Keep changes aligned with the existing workflow and documentation structure.
- Prefer local, reproducible analysis steps over ad hoc one-off edits.
- Update docs when a workflow or script changes in a user-visible way.
- Use the existing R-first workflow unless the task clearly benefits from
  Python or PowerShell.
- Avoid adding or committing raw data, scans, captures, logs, or generated
  reports.

## Git and safety

- Do not commit sensitive operational data.
- Do not add real production IP addresses, hostnames, credentials, tokens, or
  captures.
- Review `.gitignore` before introducing new output folders or generated files.
- Keep public repository content generic and reusable.

## Conflict handling

If direct system, developer, or user instructions conflict with this file,
follow the higher-priority instruction and mention the conflict when it matters
for the result.
