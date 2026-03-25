#!/usr/bin/env bash

input=$(cat)

# Extract fields from JSON input
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effortLevel // empty')
five_hr_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hr_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -z "$effort" ]; then
  effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

# user@hostname:~/path format
user=$(whoami)
hostname=$(hostname -s)
display_path="${project_dir/#$HOME/~}"

# Git branch
git_branch=$(git -C "$project_dir" --no-optional-locks branch --show-current 2>/dev/null)

# ANSI color codes
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
ORANGE=$'\033[38;5;208m'
GRAY=$'\033[38;5;245m'
RESET=$'\033[0m'

# Build a progress bar string (10 blocks) for a given integer percentage
make_bar() {
  local pct=$1 style=${2:-block}
  local filled=$(( pct / 10 ))
  local empty=$(( 10 - filled ))
  local b=""
  if [ "$style" = "dot" ]; then
    for i in $(seq 1 $filled); do b="${b}●"; done
    for i in $(seq 1 $empty); do b="${b}○"; done
  else
    for i in $(seq 1 $filled); do b="${b}█"; done
    for i in $(seq 1 $empty); do b="${b}░"; done
  fi
  echo "$b"
}

# Color for a percentage value
pct_color() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then echo "$RED"
  elif [ "$pct" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

# Format seconds into e.g. 2h34m or 45m
fmt_duration() {
  local secs=$1
  if [ "$secs" -le 0 ]; then echo "now"; return; fi
  local days=$(( secs / 86400 ))
  local hrs=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    echo "${days}d ${hrs}h"
  elif [ "$hrs" -gt 0 ]; then
    echo "${hrs}h ${mins}m"
  else
    echo "${mins}m"
  fi
}

# ── Context bar (row 1 left cell) ─────────────────────────────────────────────
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
else
  ctx_int=0
fi
ctx_bar=$(make_bar $ctx_int)
ctx_color=$(pct_color $ctx_int)
ctx_plain=" [${ctx_bar}] ${ctx_int}% "
ctx_colored=" ${ctx_color}[${ctx_bar}]${RESET} ${GRAY}${ctx_int}%${RESET} "

# ── Model/effort (row 1 right cell) ───────────────────────────────────────────
model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
if echo "$model_lower" | grep -q "haiku";  then model_color="$GREEN"
elif echo "$model_lower" | grep -q "sonnet"; then model_color="$ORANGE"
elif echo "$model_lower" | grep -q "opus";   then model_color="$RED"
else model_color="$RESET"; fi

case "$effort" in
  low)    effort_color="$GREEN" ;;
  medium) effort_color="$ORANGE" ;;
  high)   effort_color="$RED" ;;
  *)      effort_color="$RESET" ;;
esac

if [ -n "$model" ] && [ -n "$effort" ]; then
  mdl_plain=" ${model} (${effort}) "
  mdl_colored=" ${model_color}${model}${RESET} (${effort_color}${effort}${RESET}) "
elif [ -n "$model" ]; then
  mdl_plain=" ${model} "
  mdl_colored=" ${model_color}${model}${RESET} "
else
  mdl_plain="  "; mdl_colored="  "
fi

# ── 5h rate limit (row 2 left cell) ───────────────────────────────────────────
now=$(date +%s)
if [ -n "$five_hr_pct" ]; then
  fh_int=$(printf "%.0f" "$five_hr_pct")
  fh_bar=$(make_bar $fh_int dot)
  fh_color=$(pct_color $fh_int)
  if [ -n "$five_hr_reset" ]; then
    fh_left=$(fmt_duration $(( five_hr_reset - now )))
    fh_time_str=" ${fh_left}"
  else
    fh_time_str=""
  fi
  fh_plain=" 5h ${fh_bar}${fh_time_str} "
  fh_colored=" ${GRAY}5h${RESET} ${fh_color}${fh_bar}${RESET}${GRAY}${fh_time_str}${RESET} "
else
  fh_plain=" 5h — "
  fh_colored=" ${GRAY}5h —${RESET} "
fi

# ── 7d rate limit (row 2 right cell) ──────────────────────────────────────────
if [ -n "$seven_day_pct" ]; then
  sd_int=$(printf "%.0f" "$seven_day_pct")
  sd_bar=$(make_bar $sd_int dot)
  sd_color=$(pct_color $sd_int)
  if [ -n "$seven_day_reset" ]; then
    sd_left=$(fmt_duration $(( seven_day_reset - now )))
    sd_time_str=" ${sd_left}"
  else
    sd_time_str=""
  fi
  sd_plain=" 7d ${sd_bar}${sd_time_str} "
  sd_colored=" ${GRAY}7d${RESET} ${sd_color}${sd_bar}${RESET}${GRAY}${sd_time_str}${RESET} "
else
  sd_plain=" 7d — "
  sd_colored=" ${GRAY}7d —${RESET} "
fi

# ── Table layout ──────────────────────────────────────────────────────────────
repeat_char() { printf "%${2}s" | tr ' ' "$1"; }

# Column widths = max of both rows
lw1=${#ctx_plain}; lw2=${#fh_plain}
rw1=${#mdl_plain}; rw2=${#sd_plain}
lw=$(( lw1 > lw2 ? lw1 : lw2 ))
rw=$(( rw1 > rw2 ? rw1 : rw2 ))

# Pad plain widths with trailing spaces so columns align
pad_right() { local s="$1" w=$2; printf "%-${w}s" "$s"; }

ctx_plain_padded=$(pad_right "$ctx_plain" $lw)
fh_plain_padded=$(pad_right  "$fh_plain"  $lw)
mdl_plain_padded=$(pad_right "$mdl_plain" $rw)
sd_plain_padded=$(pad_right  "$sd_plain"  $rw)

# For colored cells, append spaces to match target width
ctx_pad=$(( lw - ${#ctx_plain} ))
fh_pad=$(( lw - ${#fh_plain} ))
mdl_pad=$(( rw - ${#mdl_plain} ))
sd_pad=$(( rw - ${#sd_plain} ))

ctx_cell="${ctx_colored}$(repeat_char ' ' $ctx_pad)"
fh_cell="${fh_colored}$(repeat_char ' '  $fh_pad)"
mdl_cell="${mdl_colored}$(repeat_char ' ' $mdl_pad)"
sd_cell="${sd_colored}$(repeat_char ' '  $sd_pad)"

top="${BLUE}┌$(repeat_char '─' $lw)┬$(repeat_char '─' $rw)┐${RESET}"
div="${BLUE}├$(repeat_char '─' $lw)┼$(repeat_char '─' $rw)┤${RESET}"
bot="${BLUE}└$(repeat_char '─' $lw)┴$(repeat_char '─' $rw)┘${RESET}"
row1="${BLUE}│${RESET}${ctx_cell}${BLUE}│${RESET}${mdl_cell}${BLUE}│${RESET}"
row2="${BLUE}│${RESET}${fh_cell}${BLUE}│${RESET}${sd_cell}${BLUE}│${RESET}"

# ── Line 1: user@hostname:path (branch) ───────────────────────────────────────
line1="${GREEN}${user}@${hostname}${RESET}:${BLUE}${display_path}${RESET}"
if [ -n "$git_branch" ]; then
  line1="${line1} ${YELLOW}(${git_branch})${RESET}"
fi

printf "%s\n%s\n%s\n%s\n%s\n%s\n" "$line1" "$top" "$row1" "$div" "$row2" "$bot"
