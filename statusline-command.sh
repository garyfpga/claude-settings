#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model name
model=$(echo "$input" | jq -r '.model.display_name')

# Calculate context percentage from current_usage (not cumulative totals)
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    context_pct=$((current * 100 / size))
    context_display="${context_pct}% ctx"
else
    context_display="0% ctx"
fi

# Detect running agents by checking for child claude processes
# Count claude processes that are children of our parent process
agent_count=0
if command -v pgrep >/dev/null 2>&1; then
    # Try to find agent processes - look for claude processes beyond the main one
    total_claude=$(pgrep -f "claude" 2>/dev/null | wc -l)
    # Subtract 2 (main claude + this statusline script)
    agent_count=$((total_claude - 2))
    if [ "$agent_count" -lt 0 ]; then
        agent_count=0
    fi
fi

# Build agent info string
agent_info=""
if [ "$agent_count" -gt 0 ]; then
    if [ "$agent_count" -eq 1 ]; then
        agent_info=" | 1 agent"
    else
        agent_info=" | ${agent_count} agents"
    fi
fi

# Output the status line
printf "%s | %s%s" "$model" "$context_display" "$agent_info"
