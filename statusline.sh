#!/usr/bin/env bash
set -euo pipefail

DATA=$(cat)

# Extract fields via single jq call
IFS=$'\t' read -r MODEL MODEL_ID DIR PCT CTX_SIZE DURATION_MS TOK_IN TOK_OUT VERSION < <(
    echo "$DATA" | jq -r '[
        (.model.display_name // "Claude"),
        (try (.model.id // "unknown") catch "unknown"),
        (.cwd // "~" | split("/") | last),
        (try (
    if (.context_window.remaining_percentage // null) != null then
      100 - (.context_window.remaining_percentage | floor)
    elif (.context_window.context_window_size // 0) > 0 then
      (((.context_window.current_usage.input_tokens // 0) +
        (.context_window.current_usage.cache_creation_input_tokens // 0) +
        (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
       .context_window.context_window_size) | floor
    else 0 end
  ) catch 0),
        (.context_window.context_window_size // 200000),
        (.cost.total_duration_ms // 0),
        (.context_window.total_input_tokens // 0),
        (.context_window.total_output_tokens // 0),
        (.version // "")
    ] | @tsv'
)
TOKENS=$((TOK_IN + TOK_OUT))
case "$MODEL_ID" in
  *opus*) TIER_ICON="◆" ;;
  *sonnet*) TIER_ICON="◇" ;;
  *haiku*) TIER_ICON="○" ;;
  *) TIER_ICON="●" ;;
esac

# Build progress bar
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do
  if [ $i -lt 3 ]; then BAR+="\033[38;5;140m█"
  elif [ $i -lt 6 ]; then BAR+="\033[38;5;174m█"
  else BAR+="\033[38;5;174m█"
  fi
done
for ((i=0; i<EMPTY; i++)); do BAR+="\033[38;5;240m⣀"; done

# Format duration
TOTAL_SEC=$((DURATION_MS / 1000))
H=$((TOTAL_SEC / 3600))
M=$(((TOTAL_SEC % 3600) / 60))
S=$((TOTAL_SEC % 60))
if [ "$H" -gt 0 ]; then TIME="${H}h ${M}m"
elif [ "$M" -gt 0 ]; then TIME="${M}m ${S}s"
else TIME="${S}s"
fi

# Threshold colors
if [ "$PCT" -gt 80 ]; then CTX_CLR="\033[38;5;196m"
elif [ "$PCT" -gt 50 ]; then CTX_CLR="\033[38;5;220m"
else CTX_CLR="\033[38;5;78m"
fi

echo -e "\033[38;5;141;1m$TIER_ICON\033[0m \033[38;5;111;1m$MODEL\033[0m\033[2m\033[38;5;240m·\033[0m\033[38;5;111m📁 $DIR\033[0m\033[2m\033[38;5;240m·\033[0m$BAR\033[0m ${CTX_CLR}$PCT%\033[0m\033[2m\033[38;5;240m│\033[0m\033[38;5;111m$TIME\033[0m\033[2m\033[38;5;240m│\033[0m\033[38;5;117m$TOKENS tok\033[0m\033[2m\033[38;5;240m│\033[0m\033[2m\033[38;5;240m$VERSION\033[0m\033[0m"

