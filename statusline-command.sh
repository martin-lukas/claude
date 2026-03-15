#!/usr/bin/env bash

input=$(cat)

# Extract fields from JSON input
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Project folder name (basename only)
folder=$(basename "$project_dir")

# Git branch (skip optional locks to avoid blocking)
git_branch=$(git -C "$project_dir" --no-optional-locks branch --show-current 2>/dev/null)

# ANSI color codes
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Context window usage with color thresholds
if [ -n "$used_pct" ]; then
  # Convert to integer for comparison (truncate decimals)
  used_int=$(printf "%.0f" "$used_pct")
  if [ "$used_int" -ge 90 ]; then
    context_str=$(printf "${RED}${used_int}%% ctx${RESET}")
  elif [ "$used_int" -ge 70 ]; then
    context_str=$(printf "${YELLOW}${used_int}%% ctx${RESET}")
  else
    context_str=$(printf "${GREEN}${used_int}%% ctx${RESET}")
  fi
else
  context_str=$(printf "${GREEN}0%% ctx${RESET}")
fi

# Build status line parts
parts=""

if [ -n "$folder" ]; then
  parts="$folder"
fi

if [ -n "$git_branch" ]; then
  parts="$parts ($git_branch)"
fi

if [ -n "$model" ]; then
  parts="$parts | $model"
fi

parts="$parts | $context_str"

printf "%b" "$parts"
