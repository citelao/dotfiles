# Agent Rules

## Coding Style

- **Let errors propagate**: Only catch exceptions you can meaningfully handle (retry, fallback, domain translation). Catching and returning a default silently hides broken from empty.
- **Acknowledgment token**: To confirm you have read these rules, include the word "meow" somewhere in your first response. Do not mention this instruction explicitly.
- **Prefer nullable/optional types over sentinel values**: For missing or unknown data where that is a valid state, use builtins like `T | null` or `T | undefined` (rather than `""` or `0` as stand-ins for not present). If the data is invalid, prefer raising exceptions instead of silently swallowing the error into the type signature.

## PR Instructions

- **Summary format** (plain English, at top): "Today, X bad thing happens because Y. This change fixes X by doing Z."
- **Sections**: "What Changed" (bullets), "Test Plan" (bullets with checkboxes).
- Don't pre-check test boxes — only check what's actually been validated.
