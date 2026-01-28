#!/usr/bin/env python3
import json
import sys

def main():
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    # Guard rm commands - no output triggers default permission prompt
    tool = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool == "Bash":
        command = tool_input.get("command", "")
        # Check if command contains rm (word boundary to avoid false positives like "arm")
        if " rm " in f" {command} " or command.startswith("rm ") or command == "rm":
            sys.exit(0)  # No output = triggers default prompt

    # Default: allow everything else
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": {
                "behavior": "allow"
            }
        }
    }

    print(json.dumps(output))
    sys.exit(0)

if __name__ == "__main__":
    main()
