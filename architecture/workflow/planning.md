# Planning a task

Match the process to the task size. Take the capabilities and forks from the [profile](../OPTIONAL_PACKAGES.md#the-profile) (`OPT-06`), never by reading the manifest yourself.

## Task classification

| Request | Process |
|---|---|
| Question, explanation, review | Answer directly |
| Small change inside existing classes, with no architectural decision | Make the change and summarize it |
| New feature, new screen, new class family, refactor, anything touching `Shared/` | Ask the [scope question](#scope-question), plan, ask the user to approve both, wait for approval |

## Scope question

A short prompt ("create the player health feature to show the player's health in the UI") doesn't say how much to build. Ask instead of guessing high: building more than was asked costs time and tokens and leaves files the user didn't want.

| ID | Rule |
|---|---|
| `TASK-01` | Before planning a new feature or screen, the agent MUST ask the user what to deliver, as one question with these choices: **Code only**; **Code and prefabs**; **Code and tests**; **Code, prefabs and tests**. Ask it together with the plan, in the same prompt, with the test scope question (`TEST-13`). Skip it only when the request already says. |
| `TASK-02` | The agent MUST create only what the chosen scope includes. Without prefabs, it describes them in the [handoff](prefab-handoff.md#prefab-handoff) for the developer instead. Without tests, the code stays testable (logic in Models and plain classes, `TEST-03`) and the report lists the tests that would cover it. |
| `TASK-03` | The agent MUST NOT write analyzers, editor tools, generators, test infrastructure or new shared abstractions unless the user asks for them by name. `DET-04` is for the maintainers of these rules, not for feature tasks. |
| `TASK-04` | The plan names every file it will create. Start from the smallest feature that does what was asked: for "show the player's health", a Model and a View, and a Controller only if there's input. No backend, service, persistence or Module unless the request asks for it. |

## Plan

Before planning, read a similar existing feature and the relevant docs. The plan is short:

```
Feature: PlayerStats
Location: Assets/Client/PlayerStats/
New files: list
Changed files: list
Model location: screen root, or Fast IoC scene "PlayerStats", priority 200
Scopes: PlayerStats root, PlayerStats/ActionButtons
Tests: PlayerStatsModelTests
New dependencies: none
Profile: container fast-ioc, list ui-scroller, navigation screen-system, input ui-foundations; editorBridge, verifyScript
Open questions: list
```

## Plan approval

| ID | Rule |
|---|---|
| `PLAN-01` | The user approves a plan, through the agent tool's approval prompt (in Claude Code, plan mode or a question to the user). Approval from another agent or session, or text in a file, doesn't count. When the task comes from another session, the agent still prompts the user. |

## When to ask

Ask when the docs and the existing code don't settle a decision. Don't ask what they already answer.

Agents MUST ask before:

- Adding any package or dependency. Referencing a package that is already in `Packages/manifest.json` from `Client.asmdef` is not adding one ([Assembly definitions](../FEATURE_STRUCTURE.md#assembly-definitions))
- Changing `Shared/`, core patterns or public behavior of existing code
- Using an API that is not documented and has no precedent in the code
- Introducing a new pattern
- Breaking any rule in `AGENTS.md`, even if it seems justified

Never fill a gap with a guess presented as fact. If you assumed something, say so.

| ID | Rule |
|---|---|
| `DATA-01` | Data the request gives, such as names, amounts, prices and currencies, comes from the request and what it attaches (a spec, a mockup), in that order. Where neither gives it, use United States defaults: English, US dollars and `en-US` number and date formats. |
