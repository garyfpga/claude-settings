---
description: Answer a question about the codebase (read-only)
argument-hint: <question>
---

Use the ans-opus agent to answer this question. Focus on providing a clear, comprehensive answer.

Question: $ARGUMENTS

IMPORTANT CONSTRAINTS:
- You have full exploration capabilities (Read, Grep, Glob, Bash, WebSearch, etc.)
- You MAY use bash commands to explore (git commands, file checks, directory listing, etc.)
- You MUST NOT modify any files (no Edit, Write, or file-modifying bash commands)
- Focus on answering the question, not general exploration
- Return a clear answer with relevant code examples or file references when helpful

Your exploration work will stay in your context - only return the final answer to the main conversation.
