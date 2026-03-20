# Agent Config Sharing — Results

Testing four strategies for sharing a single set of rules across multiple AI coding agents.
The rules include coding style guidance and a buried "acknowledgment token" instruction to
include "meow" in every response (used as a hard signal that the config was loaded).

## Tools tested

| Tool   | Global config location              | Notes |
|--------|-------------------------------------|-------|
| Claude | `~/.claude/CLAUDE.md`               | Supports `@path` file includes natively |
| Codex  | `~/.codex/AGENTS.md`                | No native include syntax |
| Copilot | **No global config** | CLI only reads project-level `AGENTS.md` or `.github/copilot-instructions.md`; `~/.copilot/instructions/` is VS Code-only. No global instructions support in the CLI. |
| Cursor | `~/.cursor/rules/` | TODO: not available on this machine |
| Gemini | `~/.gemini/GEMINI.md` | Supports `@path/to/file.md` includes natively; TODO: not available |

## Approaches

| Approach | Description |
|----------|-------------|
| `duplicate` | Each tool gets its own full copy of `shared/rules.md` |
| `symlink` | Each tool's config is a symlink to `shared/rules.md` |
| `reference-native` | Claude gets `@path` include; Codex gets prose stub (no native support) |
| `reference-stub` | All tools get prose-only path mention — control/baseline |

## Scores

Judged by `./judge.sh <results-dir> <tool>`. Run multiple times manually to sample variance.
Coding and PR format scored 0–3 by LLM judge (claude-sonnet-4-6).

### duplicate

| Tool   | Prompt         | Meow | Coding (0-3) | PR Format (0-3) |
|--------|----------------|------|--------------|-----------------|
| claude | greeting       | ✅   | —            | —               |
| claude | divide-fn      | ✅   | 3            | —               |
| claude | pr-description | ✅   | —            | 3               |
| codex  | greeting       | ✅   | —            | —               |
| codex  | divide-fn      | ✅   | 3            | —               |
| codex  | pr-description | ✅   | —            | 3               |

### symlink

| Tool   | Prompt         | Meow | Coding (0-3) | PR Format (0-3) |
|--------|----------------|------|--------------|-----------------|
| claude | greeting       | ✅   | —            | —               |
| claude | divide-fn      | ✅   | 3            | —               |
| claude | pr-description | ✅   | —            | 3               |
| codex  | greeting       | ✅   | —            | —               |
| codex  | divide-fn      | ✅   | 3            | —               |
| codex  | pr-description | ✅   | —            | 3               |

### reference-native

| Tool   | Prompt         | Meow | Coding (0-3) | PR Format (0-3) | Notes |
|--------|----------------|------|--------------|-----------------|-------|
| claude | greeting       | ✅   | —            | —               | `@path` include works |
| claude | divide-fn      | ✅   | 3            | —               |  |
| claude | pr-description | ✅   | —            | 3               |  |
| codex  | greeting       | ❌   | —            | —               | Gets prose stub only |
| codex  | divide-fn      | ✅   | 3            | —               | May have followed prose reference |
| codex  | pr-description | ✅   | —            | 3               | May have followed prose reference |

Codex missing meow on greeting but present on the other two is notable — possibly noise,
or the model is more likely to follow the rule when generating structured output vs. freeform.

### reference-stub (control)

| Tool   | Prompt         | Meow | Coding (0-3) | PR Format (0-3) | Notes |
|--------|----------------|------|--------------|-----------------|-------|
| claude | greeting       | ❌   | —            | —               | Prose reference not followed |
| claude | divide-fn      | ❌   | 3            | —               | Coding style likely from training |
| claude | pr-description | ❌   | —            | 2               | PR format partially correct (training) |
| codex  | greeting       | ✅   | —            | —               | Unexpected — may be noise |
| codex  | divide-fn      | ✅   | 3            | —               |  |
| codex  | pr-description | ✅   | —            | 2               |  |

Codex scoring meow on all reference-stub prompts is surprising — either Codex followed the
prose path reference and read the file, or there's something else going on. Worth re-running.
Claude's coding/PR scores without config are likely from training data, not the rules.

## Summary

- **duplicate** and **symlink** work perfectly for both tools. Symlinks are simpler to manage
  but may break in some environments (Docker, git clone, cloud sync).
- **reference-native** works for Claude. Codex has no native include support but may
  partially follow prose references — needs more runs to confirm.
- **reference-stub** is the control — Claude doesn't follow it. Codex results are ambiguous.

### duplicate (copilot)

| Tool    | Prompt         | Meow | Coding (0-3) | PR Format (0-3) | Notes |
|---------|----------------|------|--------------|-----------------|-------|
| copilot | greeting       | ❌   | —            | —               | `~/.copilot/instructions/` not read by CLI |
| copilot | divide-fn      | ❌   | 3            | —               | Coding style likely from training |
| copilot | pr-description | ❌   | —            | 2               | PR format partially correct (training) |

Copilot CLI has **no global instructions support**. `~/.copilot/instructions/` is VS Code-only.
The CLI only reads project-level `AGENTS.md` or `.github/copilot-instructions.md`.
Tested `~/AGENTS.md` — also not read. Copilot cannot be configured globally via CLI.

## TODO

- [ ] Add Cursor: global config at `~/.cursor/rules/`
- [ ] Add Gemini: global config at `~/.gemini/GEMINI.md` (supports `@path` includes)
- [ ] Re-run reference-native and reference-stub several times to reduce noise
- [ ] Test project-level configs (`.github/copilot-instructions.md`, `AGENTS.md` in repo root, etc.)
- [ ] Consider whether to keep Copilot in run-tests.sh given no global config support,
      or repurpose it as a project-level config test
