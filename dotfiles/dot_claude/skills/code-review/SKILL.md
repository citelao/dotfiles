---
name: code-review
decription: Guidelines for reviewing & auditing large code changes and PRs
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

### Giving feedback

* Concise, specific feedback.
* Focus on the most critical issues first.
* Preface nitpicks & opinions with `Nit:`.

### PR comments

* Offer to post specific review comments to the PR with `gh`.
* Ensure all comments include the trailing `(🤖 via Claude Code)`.
* Don't do this unless explicitly requested.