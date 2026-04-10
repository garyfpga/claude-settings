## Implementation and debugging with subagents

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

