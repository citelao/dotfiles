#!/usr/bin/env bash
# run-tests.sh — test agent config sharing strategies by deploying to global config locations
#
# Each approach is tested one at a time:
#   1. Back up any existing global config
#   2. Deploy test config
#   3. Run prompts from a neutral temp dir (no project-level configs)
#   4. Restore original config
#
# Global config locations:
#   Claude:  ~/.claude/CLAUDE.md
#            https://docs.anthropic.com/en/docs/claude-code/memory
#   Codex:   ~/.codex/AGENTS.md
#            https://docs.openai.com/codex-cli/memory (see "Global scope" section)
#   Gemini:  ~/.gemini/GEMINI.md  (TODO — not yet tested on this machine)
#            https://developers.google.com/gemini/docs/cli/memory
#   Cursor:  ~/.cursor/rules/     (TODO — not yet tested on this machine)
#            https://docs.cursor.com/context/rules
#
# Usage: ./run-tests.sh [--dry-run] [--no-deploy] [duplicate|symlink|reference-native|reference-stub]
#   With no approach argument, runs all four approaches sequentially.
#   --dry-run:   deploy configs and print their contents, but do not invoke any agents.
#   --no-deploy: skip backup/deploy/restore; run agents against whatever configs are currently
#                deployed. Useful for manual testing or establishing a baseline. Results are
#                saved under the approach name "current".
#   reference-native: config uses @path syntax (Claude/Gemini/Cursor natively inline the file)
#   reference-stub:   config mentions path in prose only (control/baseline — expected to fail)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$SCRIPT_DIR/shared/rules.md"
RESULTS_DIR="$SCRIPT_DIR/results"
WORK_DIR="$(mktemp -d)"  # neutral working dir with no project-level configs

# reference-native: config uses @path syntax (Claude/Gemini/Cursor support this natively)
# reference-stub:   config only mentions the path in prose (tests if agent follows it without native support)
DRY_RUN=0
NO_DEPLOY=0
APPROACHES=(duplicate symlink reference-native reference-stub)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=1; shift ;;
    --no-deploy) NO_DEPLOY=1; shift ;;
    *)           APPROACHES=("$1"); shift ;;
  esac
done

if [[ "$NO_DEPLOY" -eq 1 ]]; then
  echo "=== --no-deploy: running against current configs ==="
  run_prompts "current"
  exit 0
fi

PROMPTS=(
  "Write a one-sentence greeting."
  "Write a short TypeScript function that divides two numbers."
  "Write a PR description for a change that adds a divide function to a math utility library."
)
PROMPT_NAMES=(greeting divide-fn pr-description)

mkdir -p "$RESULTS_DIR"

BACKED_UP=()  # tracks which files were actually backed up, for restore

cleanup() {
  # Unset trap immediately to prevent double-firing (EXIT fires after INT/TERM)
  trap - EXIT INT TERM
  if [[ ${#BACKED_UP[@]} -gt 0 ]]; then
    echo ""
    echo "!!! interrupted — restoring configs..."
    for file in "${BACKED_UP[@]}"; do
      restore "$file"
    done
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Backup / restore helpers
# ---------------------------------------------------------------------------

backup() {
  local file="$1"
  if [[ -e "$file" ]]; then
    cp -P "$file" "$file.bak"
    echo "  backed up $file"
  fi
  # Always track — restore is safe to call even if no .bak exists
  BACKED_UP+=("$file")
}

restore() {
  local file="$1"
  if [[ -e "$file.bak" ]]; then
    # Replace atomically: move backup over current (whether test file or symlink)
    mv "$file.bak" "$file"
    echo "  restored $file"
  elif [[ -e "$file" ]]; then
    # No backup existed (file was absent before), so remove what we deployed
    rm -f "$file"
    echo "  removed $file (was not present before test)"
  fi
}

reset_tracked_backups() {
  BACKED_UP=()
}

# ---------------------------------------------------------------------------
# Agent runners (run from neutral WORK_DIR)
# ---------------------------------------------------------------------------

run_claude() {
  local prompt="$1" out="$2"
  # --allowedTools "" — prompts only need text responses, no tool use needed
  if ! (cd "$WORK_DIR" && claude -p "$prompt" --allowedTools "" 2>/dev/null) > "$out"; then
    echo "    WARNING: claude exited non-zero for prompt: $prompt" >&2
  fi
}

run_codex() {
  local prompt="$1" out="$2"
  # -s read-only — prompts only need text responses
  if ! codex exec -C "$WORK_DIR" --skip-git-repo-check -s read-only \
      -o "$out" "$prompt" 2>/dev/null; then
    echo "    WARNING: codex exited non-zero for prompt: $prompt" >&2
  fi
}

# TODO: add cursor once available on this machine
#   Global config: ~/.cursor/rules/
#   run_cursor() { ... }

# TODO: add gemini once available on this machine
#   Global config: ~/.gemini/GEMINI.md (supports @path/to/file.md imports)
#   run_gemini() { ... }

run_prompts() {
  local approach="$1"
  local out_dir="$RESULTS_DIR/$approach"
  mkdir -p "$out_dir"

  for i in "${!PROMPTS[@]}"; do
    local name="${PROMPT_NAMES[$i]}" prompt="${PROMPTS[$i]}"
    echo "    claude / $name"
    run_claude "$prompt" "$out_dir/claude-$name.txt"
    echo "    codex / $name"
    run_codex "$prompt" "$out_dir/codex-$name.txt"
  done
}

# ---------------------------------------------------------------------------
# Deploy strategies
# ---------------------------------------------------------------------------

deploy_duplicate() {
  # Each tool gets its own full copy of the rules
  cp "$SHARED" ~/.claude/CLAUDE.md
  cp "$SHARED" ~/.codex/AGENTS.md
  # TODO cursor: cp "$SHARED" ~/.cursor/rules/shared.mdc
  # TODO gemini: cp "$SHARED" ~/.gemini/GEMINI.md
}

deploy_symlink() {
  # Each tool's config is a symlink to a single canonical file
  local target="$SCRIPT_DIR/shared/rules.md"
  ln -sf "$target" ~/.claude/CLAUDE.md
  ln -sf "$target" ~/.codex/AGENTS.md
  # TODO cursor: ln -sf "$target" ~/.cursor/rules/shared.mdc
  # TODO gemini: ln -sf "$target" ~/.gemini/GEMINI.md
}

deploy_reference-native() {
  # @path syntax: tool natively reads and inlines the referenced file.
  # Supported by: Claude, Gemini (natively), likely Cursor.
  # Not supported by: Codex — falls back to stub behavior for comparison.
  cat > ~/.claude/CLAUDE.md <<EOF
@$SCRIPT_DIR/shared/rules.md
EOF
  # Codex has no native @include syntax, so give it the stub for comparison
  cat > ~/.codex/AGENTS.md <<EOF
# Agent Config

See rules in: $SCRIPT_DIR/shared/rules.md
EOF
  # TODO cursor: @file reference syntax in ~/.cursor/rules/ (likely supported)
  # TODO gemini: @path/to/file.md import syntax (supported natively)
  #              https://developers.google.com/gemini/docs/cli/memory#import-files
}

deploy_reference-stub() {
  # Prose-only path mention — no native include syntax. Tests whether the agent
  # will follow a plain-text instruction to consult another file.
  # Expected to fail for all tools since agents don't read arbitrary file paths
  # from their config, but useful as a baseline/control.
  cat > ~/.claude/CLAUDE.md <<EOF
# Agent Config

See rules in: $SCRIPT_DIR/shared/rules.md
EOF
  cat > ~/.codex/AGENTS.md <<EOF
# Agent Config

See rules in: $SCRIPT_DIR/shared/rules.md
EOF
  # TODO cursor, gemini: same stub
}

# ---------------------------------------------------------------------------
# Main loop — one approach at a time with backup/restore
# ---------------------------------------------------------------------------

for approach in "${APPROACHES[@]}"; do
  echo ""
  echo "=== Approach: $approach ==="

  echo "  backing up existing global configs..."
  backup ~/.claude/CLAUDE.md
  backup ~/.codex/AGENTS.md
  # TODO cursor: backup ~/.cursor/rules/shared.mdc
  # TODO gemini: backup ~/.gemini/GEMINI.md

  echo "  deploying..."
  case "$approach" in
    duplicate)         deploy_duplicate ;;
    symlink)           deploy_symlink ;;
    reference-native)  deploy_reference-native ;;
    reference-stub)    deploy_reference-stub ;;
    *) echo "Unknown approach: $approach"; exit 1 ;;
  esac

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  --- deployed configs (dry run, not invoking agents) ---"
    echo "  ~/.claude/CLAUDE.md:"; cat ~/.claude/CLAUDE.md | sed 's/^/    /'
    echo "  ~/.codex/AGENTS.md:";  cat ~/.codex/AGENTS.md  | sed 's/^/    /'
  else
    echo "  running prompts..."
    run_prompts "$approach"
  fi

  echo "  restoring..."
  restore ~/.claude/CLAUDE.md
  restore ~/.codex/AGENTS.md
  # TODO cursor: restore ~/.cursor/rules/shared.mdc
  # TODO gemini: restore ~/.gemini/GEMINI.md
  reset_tracked_backups
done

echo ""
echo "Done. Results saved to $RESULTS_DIR"
echo "Run ./judge.sh to evaluate."
