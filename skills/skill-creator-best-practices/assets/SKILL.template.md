---
name: [skill-name]
description: [Third-person statement of what the skill does]. Use when [trigger 1]. Use when [trigger 2]. Do not use for [explicit negative triggers]. Max 1,024 characters.
---

# [Skill Title]

## 概覽

[One to two sentences: what this skill does and why it matters. State the outcome, not the mechanism.]

## 使用時機

- [Positive trigger 1 — symptom, task type, or request pattern]
- [Positive trigger 2]
- [Positive trigger 3]

**不應使用的情況：** [Explicit exclusions — adjacent tasks that look similar but should route elsewhere.]

## 核心流程

### 步驟 1：[Action phase name]

1. [Third-person imperative instruction, e.g., "Extract the query parameters..."]
2. [Instruction referencing an asset, e.g., "Read `assets/template.json` to structure the final output."]

### 步驟 2：[Action phase name]

1. [Decision tree / conditional, e.g., "If source maps are required, run `scripts/build.sh`. Otherwise, skip to Step 3."]
2. [JiT-loaded reference, e.g., "Read `references/auth-flow.md` to map the specific error codes."]
3. Execute `python scripts/[script-name].py` to [perform deterministic action].

### 步驟 3：[Action phase name]

1. [Step]
2. [Step]

## 具體技巧／模式

[Detailed guidance, code examples, templates, or tables for non-obvious cases. Omit this section if the core flow already covers everything.]

```[language]
// [Minimal, illustrative example]
```

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| [Excuse an agent uses to skip a step] | [Factual rebuttal — cite the concrete cost of skipping] |
| [Excuse 2] | [Rebuttal 2] |

## 警訊

- [Observable sign the skill is being violated]
- [Behaviour to watch for during review]
- [Output shape that indicates the process was short-circuited]

## 驗證

- [ ] [Exit-criterion with concrete evidence, e.g., "All tests pass: `npm test` returns 0"]
- [ ] [Exit-criterion, e.g., "Screenshot captured at `assets/verify.png`"]
- [ ] [Exit-criterion, e.g., "No skipped or disabled tests"]

## 錯誤處理

- If `scripts/[script-name].py` fails due to [specific edge case], execute [recovery step].
- If [condition B occurs], read `references/[troubleshooting-file].md`.

## 延伸參考

- [Cross-reference other skills by name instead of duplicating, e.g., "Follow `test-driven-development` for writing tests."]
- [Link to `references/[deep-dive].md` for extended context.]
