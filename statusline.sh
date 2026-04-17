#!/usr/bin/env bash

# Single line: Model | dir@branch | tokens | %used | ac | th | 5h bar | 7d bar | extra
#
# Auto compact simplified formula:
#   current_tokens = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
#   If auto compact ON:  usable = context_window_size - 33000 (33k reserved buffer)
#   If auto compact OFF: usable = context_window_size (full window)
#   tokens_remaining = usable - current_tokens
#   Auto compact on/off: ~/.claude.json "autoCompactEnabled" (default: true if absent)
#   Can also be disabled via DISABLE_AUTO_COMPACT=true env var

set -f  # disable globbing

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ANSI colors matching oh-my-posh theme
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

# Format token counts (e.g., 50k / 200k)
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# Format number with commas (e.g., 134,938)
format_commas() {
    printf "%'d" "$1"
}

# Return color based on usage percentage
# Usage: pct_color <pct>
pct_color() {
    local pct=$1
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    if [ "$pct" -ge 90 ]; then printf "$red"
    elif [ "$pct" -ge 70 ]; then printf "$yellow"
    elif [ "$pct" -ge 50 ]; then printf "$orange"
    else printf "$green"
    fi
}

# ===== Extract data from JSON =====
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
# Shorten model name: "Claude Opus 4.6 (1M context)" → "op 4.6"
model_name=$(echo "$model_name" | sed -E '
    s/^Claude //i;
    s/Opus/op/i; s/Sonnet/sn/i; s/Haiku/hk/i;
    s/ *\(.*//;
' | tr '[:upper:]' '[:lower:]')

# Context window
size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

# Token usage
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

if [ "$size" -gt 0 ]; then
    pct_used=$(( current * 100 / size ))
else
    pct_used=0
fi
used_comma=$(format_commas $current)

# ===== Build single-line output =====
out=""
out+="${blue}${model_name}${reset}"

# Current working directory
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
    display_dir="${cwd##*/}"
    git_branch=$(git -C "${cwd}" rev-parse --abbrev-ref HEAD 2>/dev/null)
    out+=" ${dim}|${reset} "
    out+="${cyan}${display_dir}${reset}"
    if [ -n "$git_branch" ]; then
        out+="${dim}@${reset}${green}${git_branch}${reset}"
    fi
fi

out+=" ${dim}|${reset} "
out+="${orange}${used_tokens}/${total_tokens}${reset}"
# Check thinking mode from settings
thinking_mode="off"
settings_path="$HOME/.claude/settings.json"
if [ -f "$settings_path" ]; then
    thinking_type=$(jq -r '.thinking.type // empty' "$settings_path" 2>/dev/null)
    if [ -n "$thinking_type" ] && [ "$thinking_type" != "null" ]; then
        thinking_mode="$thinking_type"
    fi
fi

# Detect auto compact status
auto_compact="on"
claude_json="$HOME/.claude.json"
if [ -f "$claude_json" ]; then
    ac_val=$(jq -r '.autoCompactEnabled // true' "$claude_json" 2>/dev/null)
    [ "$ac_val" = "false" ] && auto_compact="off"
fi
[ "${DISABLE_AUTO_COMPACT}" = "true" ] && auto_compact="off"

out+=" ${dim}|${reset} "

if [ "$auto_compact" = "on" ]; then
    out+="${green}on${reset}"
else
    out+="${dim}off${reset}"
fi
out+=" ${dim}|${reset} "
case "$thinking_mode" in
    adaptive) out+="${orange}ad${reset}" ;;
    enabled)  out+="${green}on${reset}" ;;
    *)        out+="${dim}off${reset}" ;;
esac

# ===== Cross-platform OAuth token resolution (from statusline.sh) =====
# Tries credential sources in order: env var → macOS Keychain → Linux creds file → GNOME Keyring
get_oauth_token() {
    local token=""

    # 1. Explicit env var override
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi

    # 2. macOS Keychain
    if command -v security >/dev/null 2>&1; then
        local blob
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"
                return 0
            fi
        fi
    fi

    # 3. Linux credentials file
    local creds_file="${HOME}/.claude/.credentials.json"
    if [ -f "$creds_file" ]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"
            return 0
        fi
    fi

    # 4. GNOME Keyring via secret-tool
    if command -v secret-tool >/dev/null 2>&1; then
        local blob
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                echo "$token"
                return 0
            fi
        fi
    fi

    echo ""
}

# ===== LINE 2 & 3: Usage limits with progress bars (cached) =====
# Shared cache across all users on the same subscription:
#   /tmp/claude-shared/ gets sticky + world-writable (1777) so any user can
#   create files; umask 000 here makes cache + lock files mode 666 so any
#   user can overwrite them (race-safe via flock).
cache_dir="/tmp/claude-shared"
cache_file="$cache_dir/statusline-usage-cache.json"
lock_file="$cache_dir/statusline-usage.lock"
cache_max_age=120  # seconds between API calls
umask 000
mkdir -p "$cache_dir" 2>/dev/null
chmod 1777 "$cache_dir" 2>/dev/null || true

# Helper: check if cache is fresh, sets usage_data if so
check_cache() {
    if [ -f "$cache_file" ]; then
        local mtime now age
        mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        now=$(date +%s)
        age=$(( now - mtime ))
        if [ "$age" -lt "$cache_max_age" ]; then
            usage_data=$(cat "$cache_file" 2>/dev/null)
            return 0
        fi
    fi
    return 1
}

usage_data=""

# Check cache before attempting any lock
if ! check_cache; then
    # Cache is stale — try to acquire exclusive lock (non-blocking)
    exec 9>"$lock_file"
    if flock -n 9 2>/dev/null; then
        # Won the lock — re-check cache (another instance may have just refreshed it)
        if ! check_cache; then
            token=$(get_oauth_token)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                response=$(curl -s --max-time 10 \
                    -H "Accept: application/json" \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $token" \
                    -H "anthropic-beta: oauth-2025-04-20" \
                    -H "User-Agent: claude-code/2.1.34" \
                    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
                if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
                    usage_data="$response"
                    echo "$response" > "$cache_file"
                fi
            fi
        fi
        flock -u 9
    fi
    exec 9>&-
    # Fall back to stale cache if we still have no data
    if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

# Cross-platform ISO to epoch conversion
# Converts ISO 8601 timestamp (e.g. "2025-06-15T12:30:00Z" or "2025-06-15T12:30:00.123+00:00") to epoch seconds.
# Properly handles UTC timestamps and converts to local time.
iso_to_epoch() {
    local iso_str="$1"

    # Try GNU date first (Linux) — handles ISO 8601 format automatically
    local epoch
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    # BSD date (macOS) - handle various ISO 8601 formats
    local stripped="${iso_str%%.*}"          # Remove fractional seconds (.123456)
    stripped="${stripped%%Z}"                 # Remove trailing Z
    stripped="${stripped%%+*}"               # Remove timezone offset (+00:00)
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"  # Remove negative timezone offset

    # Check if timestamp is UTC (has Z or +00:00 or -00:00)
    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        # For UTC timestamps, parse with timezone set to UTC
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi

    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    return 1
}

# Format ISO reset time to compact local time
# Usage: format_reset_time <iso_string> <style: time|datetime|date>
format_reset_time() {
    local iso_str="$1"
    local style="$2"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

    # Parse ISO datetime and convert to local time (cross-platform)
    local epoch
    epoch=$(iso_to_epoch "$iso_str")
    [ -z "$epoch" ] && return

    # Format based on style — try BSD date first, fall back to GNU date
    local result=""
    case "$style" in
        time)
            result=$(date -j -r "$epoch" +"%l:%M%p" 2>/dev/null)
            if [ -n "$result" ]; then
                result=$(echo "$result" | sed 's/^ //' | tr '[:upper:]' '[:lower:]')
            else
                result=$(date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //')
            fi
            ;;
        datetime)
            result=$(date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null)
            if [ -n "$result" ]; then
                result=$(echo "$result" | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]')
            else
                result=$(date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //')
            fi
            ;;
        *)
            result=$(date -j -r "$epoch" +"%b %-d" 2>/dev/null)
            if [ -z "$result" ]; then
                result=$(date -d "@$epoch" +"%b %-d" 2>/dev/null)
            fi
            ;;
    esac
    echo "$result"
}

# Calculate time remaining until a future ISO timestamp
# Usage: time_until <iso_string> <style: hm|dh>
time_until() {
    local iso_str="$1"
    local style="$2"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return

    local epoch
    epoch=$(iso_to_epoch "$iso_str")
    [ -z "$epoch" ] && return

    local now=$(date +%s)
    local diff=$(( epoch - now ))
    [ "$diff" -le 0 ] && diff=0

    case "$style" in
        hm)
            local hours=$(( diff / 3600 ))
            local mins=$(( (diff % 3600) / 60 ))
            printf "%dh%dm" "$hours" "$mins"
            ;;
        dh)
            local days=$(( diff / 86400 ))
            local hours=$(( (diff % 86400) / 3600 ))
            printf "%dd%dh" "$days" "$hours"
            ;;
    esac
}

sep=" ${dim}|${reset} "

if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
    # ---- 5-hour (current) ----
    five_hour_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
    five_hour_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
    five_hour_reset=$(time_until "$five_hour_reset_iso" "hm")
    five_hour_color=$(pct_color "$five_hour_pct")

    out+="${sep}${white}5h${reset} ${five_hour_color}${five_hour_pct}%${reset}"
    [ -n "$five_hour_reset" ] && out+=" ${dim}${five_hour_reset}${reset}"

    # ---- 7-day (weekly) ----
    seven_day_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
    seven_day_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')
    seven_day_reset=$(time_until "$seven_day_reset_iso" "dh")
    seven_day_color=$(pct_color "$seven_day_pct")

    out+="${sep}${white}7d${reset} ${seven_day_color}${seven_day_pct}%${reset}"
    [ -n "$seven_day_reset" ] && out+=" ${dim}${seven_day_reset}${reset}"

    # ---- Extra usage ----
    extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
    if [ "$extra_enabled" = "true" ]; then
        extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
        extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
        extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
        extra_color=$(pct_color "$extra_pct")

        out+="${sep}${white}extra${reset} ${extra_color}\$${extra_used}/\$${extra_limit}${reset}"
    fi
fi

# Output single line
printf "%b" "$out"

exit 0

