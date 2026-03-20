#!/usr/bin/env bash
# judge.sh — evaluate agent responses from run-tests.sh
#
# Usage: ./judge.sh <results-dir> <tool>
#   results-dir   Directory containing <tool>-*.txt files
#                 e.g. ./results/current
#   tool          claude | codex | cursor | gemini
#
# Run multiple times manually to get a sense of judge variance.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 2 ]]; then
  echo "Usage: ./judge.sh <results-dir> <tool>"
  echo "  e.g. ./judge.sh results/current claude"
  exit 1
fi

RESULTS_DIR="$1"
TOOL="$2"

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "Directory not found: $RESULTS_DIR"
  exit 1
fi

PROMPT_NAMES=(greeting divide-fn pr-description)

# ---------------------------------------------------------------------------
# Hard check: did the response include "meow"?
# ---------------------------------------------------------------------------
check_meow() {
  local file="$1"
  if grep -qi "meow" "$file" 2>/dev/null; then
    echo "1"
  else
    echo "0"
  fi
}

# ---------------------------------------------------------------------------
# Soft judge: call claude -p to score a response 0-3 on a rubric
# ---------------------------------------------------------------------------
JUDGE_CODING_STYLE='You are a strict code reviewer. Score the following response 0-3 based on how well it follows these coding style rules:
- Errors should propagate; do not catch and return a default value silently.
- Use nullable/optional types (T | null, T | undefined) for missing data rather than sentinel values like "" or 0.

Reply with ONLY a single integer 0, 1, 2, or 3. No explanation.

Response to score:
---
RESPONSE_PLACEHOLDER
---'

JUDGE_PR_FORMAT='You are evaluating a PR description. Score it 0-3:
- 0: Does not resemble a PR description
- 1: Has some structure but missing key sections
- 2: Has a plain-English summary and either "What Changed" or "Test Plan" section
- 3: Has a plain-English summary, "What Changed" bullets, and "Test Plan" with unchecked checkboxes

Reply with ONLY a single integer 0, 1, 2, or 3. No explanation.

Response to score:
---
RESPONSE_PLACEHOLDER
---'

judge() {
  local rubric="$1" response="$2"
  local prompt="${rubric/RESPONSE_PLACEHOLDER/$response}"
  local s
  s=$(claude -p "$prompt" --allowedTools "" 2>/dev/null | tr -d '[:space:]')
  if [[ "$s" =~ ^[0-3]$ ]]; then
    echo "$s"
  else
    echo "?"
  fi
}

# ---------------------------------------------------------------------------
# Score
# ---------------------------------------------------------------------------
printf "\n%-14s %-8s %-16s %-16s\n" "PROMPT" "MEOW" "CODING (0-3)" "PR FORMAT (0-3)"
printf '%0.s-' {1..56}; echo

for name in "${PROMPT_NAMES[@]}"; do
  file="$RESULTS_DIR/$TOOL-$name.txt"
  if [[ ! -f "$file" ]]; then
    printf "%-14s %-8s %-16s %-16s\n" "$name" "MISSING" "-" "-"
    continue
  fi

  response="$(cat "$file")"
  meow=$(check_meow "$file")

  if [[ "$name" == "divide-fn" ]]; then
    coding=$(judge "$JUDGE_CODING_STYLE" "$response")
    pr="-"
  elif [[ "$name" == "pr-description" ]]; then
    coding="-"
    pr=$(judge "$JUDGE_PR_FORMAT" "$response")
  else
    coding="-"
    pr="-"
  fi

  printf "%-14s %-8s %-16s %-16s\n" "$name" "$meow" "$coding" "$pr"
done

echo ""
echo "MEOW: 1=present, 0=absent"
