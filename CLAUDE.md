## Parallel implementation with subagents
- When implementing a plan that touches 3+ independent files, use the Task tool with `subagent_type="general-purpose"` to edit multiple files in parallel
- Each subagent prompt MUST include:
  - The full relevant section of the plan (not just a summary)
  - Exact file path(s) to edit
  - Specific code changes expected (function signatures, logic, imports)
  - Any conventions or patterns to follow (naming, typing, style)
  - Relevant context from other files (types, interfaces, function signatures the code depends on)
- The goal is that the subagent has everything it needs to produce the exact code you would write yourself
- Only parallelize truly independent edits — if file B depends on changes in file A, edit A first

## Output size limit
Your max output token is set to 48k. When producing large outputs (e.g., writing or editing a large file, generating lengthy code), do NOT attempt to fit everything into a single response. Instead, break the work into multiple turns — write one section, then continue in the next turn. This avoids truncation and ensures all content is delivered completely. Prefer using the Edit tool for targeted changes over rewriting entire files.

