---
name: gh-multi-account-push
description: Push/fetch a git repo owned by a non-active GitHub account without changing the globally-active gh account. Use on a 401/403 or account-mismatch when `gh auth status` shows the repo's owning account is logged in but not active.
---

Handle a git auth failure caused by **multiple gh accounts** — where the repo belongs to one account but a *different* account is globally active — without ever changing global state.

## When to use

- A `git push`/`fetch` fails with **403 Permission denied** or **401**, and the denied user in the error is not the account that owns the repo.
- `gh auth status` shows the owning account **is logged in** (in the keyring) but is **not** the active one.
- Any time switching the active account would be wrong because other agents may be running in parallel.

If the owning account is **not** in the keyring at all (and no suitable token is in the env), stop and ask — don't invent credentials or trigger an interactive login.

## Hard rules

- **Never run `gh auth switch`** — it's global state; parallel agents depend on the current active account.
- **Never** add SSH keys, edit `~/.gitconfig`/global git config, or change any gh/global config as a workaround.
- **Never print a token in cleartext** — mask it in any echoed output.
- Keep the token **in-memory, single-command** — don't write it to disk, env files, or git config.

## The technique

1. Identify the account that owns the repo (match the remote host + org to `gh auth status`).
2. Pull *that* account's token from the keyring without making it active:
   ```
   gh auth token --hostname <host> --user <account>
   ```
   (`<host>` is e.g. `github.com`; `--user` selects a non-active keyring account.)
3. Use it for a single push/fetch, with the credential helper disabled so git doesn't fall back to the keychain helper bound to the active account. Embed the token in the URL — this is more reliable than `http.extraHeader`, which has prompted for a username in practice:
   ```
   T="$(gh auth token --hostname github.com --user <account>)"
   git -c credential.helper= push "https://x-access-token:${T}@github.com/<org>/<repo>.git" <branch>
   ```
4. **Mask the token** in any output you surface:
   ```
   ... 2>&1 | sed -E "s/${T}/***TOKEN***/g"
   ```
5. Verify with `git fetch` + compare `origin/<branch>`; the pre-push `ahead/behind` status is a stale snapshot, not proof of failure.

## Notes

- `-c credential.helper=` (empty value) is what prevents the `could not read Username for 'https://github.com'` fallback.
- Prefer this over stop-and-ask whenever the owning account's token is retrievable — it's the intended path, not a workaround.
- Repo-specific token facts (which account owns which repo) belong in project memory, not here; this skill is the host-agnostic method.
