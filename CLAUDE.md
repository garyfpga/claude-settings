## Implementation and debugging with subagents

### Coder agent (Sonnet 4.6) — `subagent_type="coder"`
Use for all code implementation tasks: new features, refactoring, multi-file edits.
- When a plan touches 3+ independent files, launch multiple coder agents in parallel
- Each agent prompt MUST include:
  - The full relevant section of the plan (not just a summary)
  - Exact file path(s) to edit
  - Specific code changes expected (function signatures, logic, imports)
  - Relevant context from other files (types, interfaces, function signatures the code depends on)
- The goal is that the agent has everything it needs to produce the exact code you would write yourself
- Only parallelize truly independent edits — if file B depends on changes in file A, edit A first

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

## Tables in comments
ASCII tables in code comments must be readable in the raw file. In C++, wrap with `// clang-format off` / `// clang-format on` to prevent reformatting.

## Linting errors
- Do NOT check `<new-diagnostics>` after every individual edit — they are often stale (from the pre-edit language server state)
- Instead, batch your edits first, then verify once at the end of a batch of related edits
- **Python**: Run `uv run pyright path/to/file.py` for fresh, accurate type checking
- **C++**: clangd shows many false errors (missing includes, unknown members) because it can't resolve include paths. Ignore clangd `<new-diagnostics>` entirely — verify with `xmake b <target>` instead
- Fix any type/build errors before moving on to the next task

## Web Search
When searching for information from the web, kick both `WebSearch` (built-in) and the `web-search` MCP tools in parallel simultaneously — they use different backends and together improve coverage and reliability.

