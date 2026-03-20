#!/usr/bin/env bash
# judge.sh — evaluate agent responses from run-tests.sh
#
# Usage: ./judge.sh [--runs N] <results-dir>
#   --runs N       Number of times to re-judge each soft response (default: 3)
#   results-dir    Directory containing claude-*.txt / codex-*.txt files
#                  e.g. ./results/current or ./results/duplicate
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNS=3
RESULTS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs) RUNS="$2"; shift 2 ;;
    *)      RESULTS_DIR="$1"; shift ;;
  esac
done

if [[ -z "$RESULTS_DIR" ]]; then
  echo "Usage: ./judge.sh [--runs N] <results-dir>"
  echo "  e.g. ./judge.sh results/current"
  exit 1
fi
if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "Directory not found: $RESULTS_DIR"
  exit 1
fi

# TODO: add cursor and gemini once available on this machine
TOOLS=(claude codex)
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
# Returns a single integer. Called $RUNS times per response; caller averages.
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

judge_once() {
  local rubric="$1" response="$2"
  local prompt="${rubric/RESPONSE_PLACEHOLDER/$response}"
  claude -p "$prompt" --allowedTools "" 2>/dev/null | tr -d '[:space:]'
}

# Run judge $RUNS times, compute mean and stddev, print "mean stddev"
judge_multi() {
  local rubric="$1" response="$2"
  local scores=()
  for ((i=0; i<RUNS; i++)); do
    local s
    s=$(judge_once "$rubric" "$response")
    # Validate it's a digit 0-3, else treat as 0
    if [[ "$s" =~ ^[0-3]$ ]]; then
      scores+=("$s")
    else
      scores+=("0")
    fi
  done

  # Compute mean and stddev in awk
  printf '%s\n' "${scores[@]}" | awk '
    { sum += $1; vals[NR] = $1 }
    END {
      mean = sum / NR
      for (i=1; i<=NR; i++) sq += (vals[i]-mean)^2
      stddev = (NR > 1) ? sqrt(sq/(NR-1)) : 0
      printf "%.2f ± %.2f", mean, stddev
    }
  '
}

# ---------------------------------------------------------------------------
# Main scoring loop
# ---------------------------------------------------------------------------
printf "\n%-8s %-14s %-8s %-16s %-16s\n" \
  "TOOL" "PROMPT" "MEOW" "CODING (0-3)" "PR FORMAT (0-3)"
printf '%0.s-' {1..64}; echo

for tool in "${TOOLS[@]}"; do
  for name in "${PROMPT_NAMES[@]}"; do
    file="$RESULTS_DIR/$tool-$name.txt"
    if [[ ! -f "$file" ]]; then
      printf "%-8s %-14s %-8s %-16s %-16s\n" \
        "$tool" "$name" "MISSING" "-" "-"
      continue
    fi

    response="$(cat "$file")"
    meow=$(check_meow "$file")

    if [[ "$name" == "divide-fn" ]]; then
      coding=$(judge_multi "$JUDGE_CODING_STYLE" "$response")
      pr="-"
    elif [[ "$name" == "pr-description" ]]; then
      coding="-"
      pr=$(judge_multi "$JUDGE_PR_FORMAT" "$response")
    else
      coding="-"
      pr="-"
    fi

    printf "%-8s %-14s %-8s %-16s %-16s\n" \
      "$tool" "$name" "$meow" "$coding" "$pr"
  done
done

echo ""
echo "MEOW: 1=present, 0=absent  |  Scores averaged over $RUNS judge runs"
