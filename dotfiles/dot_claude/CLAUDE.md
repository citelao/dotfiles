# Personal Preferences

## Workflow

- **Fix errors, don't remove validation**: Never remove tests, CI checks, or type validation to make errors go away. Fix the underlying issue instead.
- **Incremental commits**: Work in small, logical extract+wire+delete chunks. Don't commit unused code — every commit should be self-contained and functional.
- **Clean git tree**: I review diffs in my editor. Summarize what's in each chunk rather than dumping large diffs in the terminal. Don't create files you don't expect to commit yet — keep the working tree clean.
- **Rebase workflow**: When a base branch has been merged to main, use `git rebase --onto origin/main <old-base-tip> <branch>` to cleanly rebase without conflicts from the merged base.

## PRs

- Format: "Today, X is the problem. This change does Y."
- Sections: What changed (bullets), How tested (bullets).
- Don't pre-check test boxes — only check what's actually been validated.
- **Claude Code warning**: Include a note block at the top of the PR body when generated via Claude Code:
  ```markdown
  > [!NOTE]
  > Generated via Claude Code.
  ```

