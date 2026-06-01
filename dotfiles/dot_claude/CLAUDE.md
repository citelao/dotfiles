# Personal Preferences

> **Chezmoi**: This file is managed by chezmoi. To edit, run `chezmoi source-path` to find the source directory, then edit `dot_claude/CLAUDE.md` there. Run `chezmoi apply` after editing.

## Workflow

- **Fix errors, don't remove validation**: Never remove tests, CI checks, or type validation to make errors go away. Fix the underlying issue instead.
- **Clear, useful, small commits**: Work in small, chunks that deliver user-facing changes. Each commit should meaningfully affect the product in some meaningful way; don't check in unused code.
- **Clean git tree**: I review diffs in my editor. Summarize what's in each chunk rather than dumping large diffs in the terminal. Don't create files you don't expect to commit yet — keep the working tree clean.
- **Write red-green tests**: When writing tests, prefer to write *failing* tests that you then fix; if the fix is already written, temporarily disable it to ensure your tests are useful.

## Coding style

- **Let errors propagate**: Only catch exceptions you can meaningfully handle (retry, fallback, domain translation). Catching and returning a default silently hides broken from empty.
- **Prefer nullable/optional types over sentinel values**: For missing or unknown data where that is a valid state, use builtins like `T | null` or `T | undefined` (rather than `""` or `0` as stand-ins for not present). If the data is invalid, prefer raising exceptions instead of silently swallowing the error into the type signature.
- **Parse untrusted data with schemas**: Validate any data your code didn't construct itself (HTTP/WS/IPC payloads, JSON from disk, env-var JSON), preferably with a schema library (e.g. zod, pydantic). Don't substitute ad-hoc runtime checks or unchecked casts for a schema. Derive the type from the schema rather than declaring a parallel one.

## Communication style

- **Prefer 1-line commit messages**: prefer 1-line commit messages within ~80chars. Longer descriptions belong in PRs.
- **Co-author yourself on commits**: append `Co-authored-by: ...` (e.g. `Co-authored-by: Claude <noreply@anthropic.com>`).
- **Avoid folder-structure docs/comments**: I generally dislike documentation or comments that describe folder structure, because they become obsolete quickly and usually are not kept up to date.
- **Comment non-obvious code**: If the purpose of code is not immediately obvious from its name (e.g. workaround for an external quirk, atypical calling pattern, code that appears complex but is actually simple), strongly consider adding a why-comment. Does the comment make it easier for readers, or does it add noise?

## Tool call tips

- **Avoid printing dividers that look like flags**: `echo "---"` can trigger security cues because it looks like a flag; prefer `echo "==="` instead.
- **Avoid using `git -C` for the current repo**: this makes it hard to auto-approve commands. Be aware of which repo you are in, and use standard `git` commands for the current repo.

## PRs

- **Summary format** (plain English, at top): "Today, X bad thing happens because Y. This change fixes X by doing Z."
- **Claude Code note** (below summary):
  ```markdown
  > [!NOTE]
  > Generated via Claude Code.
  ```
- **Sections**: "What Changed" (bullets), "Test Plan" (bullets with checkboxes).
- Don't pre-check test boxes — only check what's actually been validated.
