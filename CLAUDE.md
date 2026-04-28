# CLAUDE.md

## Always launch subagent in background such that Claude will be able to response to new prompt

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

## 5. Subagent implementation

1. in planning mode, always analysis the DAG for the work, and plan for dispatching multiple agent in background in parallel.
2. when a subagent complete, check the task list and the DAG if we can dispatching more task
3. for simple tasks where the code changes is already state in plan, use haiku
4. for complex tasks use sonnet, including tasks that requiring running the tests, do not run tests in the main agent
5. all testing has to be run with a proper timeout value, total estimated test time for a PR should not exceeds 15 minutes
6. if subagents hit unexpected results / error, just fix it in the main agent

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

## Polars write_parquet
- Always use `use_pyarrow=True` in all `.write_parquet()` calls
- Polars 1.31.0 native parquet writer has a bug that corrupts FixedSizeList/Array columns when multiple `write_parquet()` calls happen sequentially in the same process (buffer reuse in repetition-level encoding)
- PyArrow writer is ~2.5x slower but correct; write time is negligible vs computation

## AskUserQuestion
Whenever you use AskUserQuestion, lay down the pros and cons and suggest a default and tell user why

