### Debugger agent (Opus 4.6) — `subagent_type="debugger"`
Use when hitting unexpected bugs, test failures, or runtime errors.
- Launch when: tests fail unexpectedly, output is wrong, crashes occur, type errors appear
- The prompt MUST include:
  - The error message / stack trace / test output
  - The file path(s) involved
  - What was expected vs what happened
  - Any recent changes that might be related
- The debugger will: reproduce → isolate → diagnose root cause → fix → verify
- Do NOT use the debugger for planned implementation work — use coder instead

## Output size limit
Your max output token is set to 48k. When producing large outputs (e.g., writing or editing a large file, generating lengthy code), do NOT attempt to fit everything into a single response. Instead, break the work into multiple turns — write one section, then continue in the next turn. This avoids truncation and ensures all content is delivered completely. Prefer using the Edit tool for targeted changes over rewriting entire files.

## Linting errors
- Do NOT check `<new-diagnostics>` after every individual edit — they are often stale (from the pre-edit language server state)
- Instead, batch your edits first, then verify once at the end of a batch of related edits
- **Python**: Run `uv run pyright path/to/file.py` for fresh, accurate type checking
- **C++**: clangd shows many false errors (missing includes, unknown members) because it can't resolve include paths. Ignore clangd `<new-diagnostics>` entirely — verify with `xmake b <target>` instead
- Fix any type/build errors before moving on to the next task
