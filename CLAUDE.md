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

## Output size limit
Your max output token is set to 48k. When producing large outputs (e.g., writing or editing a large file, generating lengthy code), do NOT attempt to fit everything into a single response. Instead, break the work into multiple turns — write one section, then continue in the next turn. This avoids truncation and ensures all content is delivered completely. Prefer using the Edit tool for targeted changes over rewriting entire files.

## Codex MCP
- A Codex MCP tool (`mcp__codex__codex`) is available for invoking OpenAI Codex CLI
- Do NOT use it unless the user explicitly asks you to

