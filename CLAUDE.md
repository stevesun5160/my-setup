## Search Strategy

- You are operating in an environment where `ast-grep` and `TypeScript LSP` installed.
- If LSP or ast-grep can handle it, do not fall back to plain text search
- Choose the search tool based on the task:
  - **Semantic operations** (go-to-definition, find references, call hierarchy, rename) → prefer **LSP**
  - **Structural pattern search** (AST pattern matching, specific syntax structures) → prefer **ast-grep** (`ast-grep --lang [language] -p '<pattern>'`)
  - **Plain text search, filename matching** → use built-in **Grep / Glob**

## Use GitHub CLI

- Prefer `gh` for all GitHub operations (PRs, issues, repo info, actions)

## Response Guide

- Before writing any code, describe your approach and wait for approval. If requirements are ambiguous, ask clarifying questions first.
- After you finish writing any code, list the edge cases and suggest test cases to cover them.
- If a task requires changes to more than 3 files, stop and break it into smaller tasks first.

## Compact Instructions

Preserve:

- Architecture decisions (NEVER summarize)
- Modified files and key changes
- Current verification status (pass/fail commands)
- Open risks, TODOs, rollback notes
