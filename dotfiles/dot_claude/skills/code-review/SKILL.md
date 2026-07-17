---
name: code-review
description: Guidelines for reviewing & auditing large code changes and PRs
---

Review large code changes and PRs.

## When to use

- When asked to review code.
- When making large changes that might benefit from a critical eye.

## What to do

### Sourcing data

* **Throughly read changes**. Use `git` history & status to understand what changes to review. Review the entire diff!
* **Understand prior work**. Use `gh pr` commands to understand existing comments & changes. What is this work trying to do? Does it do it?

### Critical areas

Focus on these critical areas:

* **Is the change correct?** Does the code even work? Are there situations that this code won't account for? Is it missing part of the larger picture?
* **Are there bugs?** Does the code actually solve the problem? Does it introduce new failures? Is it incomplete?
* **Is the change tested well?** What critical areas should be tested? What edge-cases exist? Especially consider tests that have low overhead but test critical aspects. Focus on the most complicated & critical aspects of the code, rather than unit tests that exercise obviously-working components (e.g. test business logic edge-cases, not getters and setters).
* **Is the change well-designed and simple?** Is this the clearest approach? Is this idiomatic code? Does the code match existing paradigms in the codebase?

### Ben-isms

Here are some other things to look for that are more stylistic (and often deserve `Nit` caveats, since this is my opinion):

* **PRs should be incremental** Don't existing comments, debug code, or cleanup unrelated code. Does each line of the PR materially contribute to the stated goals of the PR? If not, that change probably belongs in a separate PR.
* **Comments should be focused & important** Sometimes---sometimes---long comments are useful. Mostly they are not. Does the comment state something uniquely valuable to readers that is unclear from the code? Rule of thumb: comment size should be inversely proportional to the LOC size of the code.
* **Comments should be relevant beyond the PR** AI agents tend to write apologetic comments when fixing errors while iterating. These do not belong in the PR. Will this comment make sense without knowing how the PR was iterated?
* **Named booleans** When writing if conditions, it's often helpful to break complicated Boolean logic into a named var (e.g. `const isNewFeatureEnabled`) instead of inlining the logic. Ask: would this help document the intent of the if condition?

### Giving feedback

* Concise, specific feedback.
* Focus on the most critical issues first.
* Preface nitpicks & opinions with `Nit:`.

### Next steps: fixing issues

* If asked, fix issues as requested.
* Work in chunks: fix issues in auditable commits.
* Don't do anything unless explicitly requested.

### Next steps: PR comments

* Offer to post specific review comments to the PR with `gh`.
* Ensure all comments include the trailing `(🤖 via Claude Code)`.
* Don't do anything unless explicitly requested.