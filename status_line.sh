#!/usr/bin/env bash

input=$(cat)

# Extract fields from JSON input
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effortLevel // empty')
five_hr_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hr_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

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

# Color for context usage: gray <50%, orange 50-69%, red ≥70%
ctx_color() {
  local pct=$1
  if [ "$pct" -ge 70 ]; then echo "$RED"
  elif [ "$pct" -ge 50 ]; then echo "$ORANGE"
  else echo "$GRAY"; fi
}

# Build a progress bar with colored filled blocks and gray empty blocks
make_ctx_bar() {
  local pct=$1 color=$2
  local filled=$(( pct / 10 ))
  local empty=$(( 10 - filled ))
  local b=""
  for i in $(seq 1 $filled); do b="${b}${color}█"; done
  for i in $(seq 1 $empty); do b="${b}${GRAY}░"; done
  echo "$b"
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

WHITE=$'\033[97m'
SEP="${WHITE}│${RESET}"

strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'; }

# ── Model/effort ───────────────────────────────────────────────────────────────
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
  mdl_part="${model_color}${model}${RESET} (${effort_color}${effort}${RESET})"
elif [ -n "$model" ]; then
  mdl_part="${model_color}${model}${RESET}"
else
  mdl_part=""
fi

# ── Context percentage ─────────────────────────────────────────────────────────
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
else
  ctx_int=0
fi
ctx_c=$(ctx_color $ctx_int)
ctx_bar=$(make_ctx_bar $ctx_int "$ctx_c")
ctx_pct=$(printf "%2d%%" $ctx_int)
ctx_part="${ctx_bar}${RESET} ${ctx_c}${ctx_pct}${RESET}"

# ── 5h rate limit ──────────────────────────────────────────────────────────────
now=$(date +%s)
if [ -n "$five_hr_pct" ]; then
  fh_int=$(printf "%.0f" "$five_hr_pct")
  fh_bar=$(make_bar $fh_int dot)
  fh_color=$(pct_color $fh_int)
  if [ -n "$five_hr_reset" ]; then
    fh_left=$(fmt_duration $(( five_hr_reset - now )))
    fh_time_str=" (${fh_left})"
  else
    fh_time_str=""
  fi
  fh_part="${GRAY}5h${RESET} ${fh_color}${fh_bar}${RESET}${GRAY}${fh_time_str}${RESET}"
else
  fh_part="${GRAY}5h —${RESET}"
fi

# ── Align col 1 widths so separators line up ──────────────────────────────────
mdl_vis=$(strip_ansi "$mdl_part"); mdl_len=${#mdl_vis}
ctx_vis=$(strip_ansi "$ctx_part"); ctx_len=${#ctx_vis}
if [ "$mdl_len" -gt "$ctx_len" ]; then
  ctx_part="${ctx_part}$(printf '%*s' $(( mdl_len - ctx_len )) '')"
elif [ "$ctx_len" -gt "$mdl_len" ]; then
  mdl_part="${mdl_part}$(printf '%*s' $(( ctx_len - mdl_len )) '')"
fi

# ── Line 1: model/effort │ user@hostname:path (branch) ────────────────────────
loc="${GREEN}${user}@${hostname}${RESET}:${BLUE}${display_path}${RESET}"
if [ -n "$git_branch" ]; then
  loc="${loc} ${YELLOW}(${git_branch})${RESET}"
fi
line1="${mdl_part} ${SEP} ${loc}"

# ── Line 2: context │ 5h │ 🕑 time ────────────────────────────────────────────
current_time=$(date +%H:%M)
line2="${ctx_part} ${SEP} ${fh_part} ${SEP} 🕑 ${WHITE}${current_time}${RESET}"

printf "%s\n%s\n" "$line1" "$line2"
