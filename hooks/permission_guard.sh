#!/usr/bin/env python3
import json
import sys

def main():
    # Read hook input (you can inspect it if you ever want smarter logic)
    try:
        _input_data = json.load(sys.stdin)
    except Exception:
        # If something weird happens, just let the normal flow proceed
        sys.exit(0)

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

