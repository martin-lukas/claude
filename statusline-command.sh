#!/usr/bin/env bash

input=$(cat)

# Extract fields from JSON input
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effortLevel // empty')
if [ -z "$effort" ]; then
  effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

# user@hostname:~/path format
user=$(whoami)
hostname=$(hostname -s)
display_path="${project_dir/#$HOME/~}"

# Git branch (skip optional locks to avoid blocking)
git_branch=$(git -C "$project_dir" --no-optional-locks branch --show-current 2>/dev/null)

# ANSI color codes (real escape bytes via $'...' syntax)
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
ORANGE=$'\033[38;5;208m'
PURPLE=$'\033[35m'
GRAY=$'\033[38;5;245m'
RESET=$'\033[0m'

# Context bar
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
else
  used_int=0
fi

if [ "$used_int" -ge 90 ]; then
  bar_color="$RED"
elif [ "$used_int" -ge 70 ]; then
  bar_color="$YELLOW"
else
  bar_color="$GREEN"
fi

filled=$(( used_int / 10 ))
empty=$(( 10 - filled ))
bar=""
for i in $(seq 1 $filled); do bar="${bar}█"; done
for i in $(seq 1 $empty); do bar="${bar}░"; done

# Model color
model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
if echo "$model_lower" | grep -q "haiku"; then
  model_color="$GREEN"
elif echo "$model_lower" | grep -q "sonnet"; then
  model_color="$ORANGE"
elif echo "$model_lower" | grep -q "opus"; then
  model_color="$RED"
else
  model_color="$RESET"
fi

# Effort color
case "$effort" in
  low)    effort_color="$GREEN" ;;
  medium) effort_color="$ORANGE" ;;
  high)   effort_color="$RED" ;;
  *)      effort_color="$RESET" ;;
esac

# Line 1: user@hostname:path (branch)
line1="${GREEN}${user}@${hostname}${RESET}:${BLUE}${display_path}${RESET}"
if [ -n "$git_branch" ]; then
  line1="${line1} ${YELLOW}(${git_branch})${RESET}"
fi

# Table cell plain text (for width) and colored text
left_plain=" [${bar}] ${used_int}% "
left_colored=" ${bar_color}[${bar}]${RESET} ${GRAY}${used_int}%${RESET} "

if [ -n "$model" ] && [ -n "$effort" ]; then
  right_plain=" ${model} (${effort}) "
  right_colored=" ${model_color}${model}${RESET} (${effort_color}${effort}${RESET}) "
elif [ -n "$model" ]; then
  right_plain=" ${model} "
  right_colored=" ${model_color}${model}${RESET} "
else
  right_plain="  "
  right_colored="  "
fi

lw=${#left_plain}
rw=${#right_plain}

repeat_char() { printf "%${2}s" | tr ' ' "$1"; }

top="${BLUE}┌$(repeat_char '─' $lw)┬$(repeat_char '─' $rw)┐${RESET}"
mid="${BLUE}│${RESET}${left_colored}${BLUE}│${RESET}${right_colored}${BLUE}│${RESET}"
bot="${BLUE}└$(repeat_char '─' $lw)┴$(repeat_char '─' $rw)┘${RESET}"

printf "%s\n%s\n%s\n%s\n" "$line1" "$top" "$mid" "$bot"
