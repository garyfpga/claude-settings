#!/bin/bash
# Post-edit hook to automatically format C/C++ files with clang-format
# Triggered after Edit or Write tools are used on .h, .hpp, .c, or .cpp files

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract the file path from the JSON input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Check if file matches C/C++ extensions
if [[ "$FILE_PATH" =~ \.(h|hpp|c|cpp)$ ]]; then
  clang-format -i "$FILE_PATH"
  echo "Formatted $FILE_PATH" >&2
fi

exit 0
