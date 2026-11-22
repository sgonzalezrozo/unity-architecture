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
| `TASK-02` | The agent MUST create only what the chosen scope includes. Without prefabs, it MUST NOT build any, and it writes everything a person still has to set up in Unity to the feature's `IMPLEMENTATION.md` (`HAND-07`). Without tests, the code stays testable (logic in Models and plain classes, `TEST-03`) and the report lists the tests that would cover it. |
| `TASK-03` | The agent MUST NOT write analyzers, editor tools, generators, test infrastructure or new shared abstractions unless the user asks for them by name. `DET-04` is for the maintainers of these rules, not for feature tasks. |
| `TASK-04` | The plan names every file it will create. Start from the smallest feature that does what was asked: for "show the player's health", a Model and a View, and a Controller only if there's input. No backend, service, persistence or Module unless the request asks for it. The code MUST NOT add a command, event, file or feature the approved plan doesn't name; if one turns out necessary, the agent asks before adding it. |
| `TASK-05` | The plan's file list MUST come from the [feature files](#feature-files) table, row by row, so two runs of the same request plan the same files. A row's file is in the plan exactly when its condition holds. |

## Plan

Before planning, read a similar existing feature and the relevant docs. The plan is short, and its files come from the [feature files](#feature-files) table:

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

## Feature files

Go through every row (`TASK-05`). Write the reason next to each file in the plan.

| File | Condition |
|---|---|
| `{Screen}/{Screen}Model.cs` or `{Name}Model.cs` | Always: the feature has state. Where it lives: [Where a Model lives](../mvc/where-a-model-lives.md) |
| `{Screen}/{Name}View.cs` | Something is shown |
| `{Screen}/{Action}Controller.cs` | The request names an input (click, drag, typing). None otherwise |
| `{Screen}/{Name}Data.cs` | Items or records are listed or stored |
| `{Screen}/{Name}Scroller.cs`, `{Name}SlotModel.cs`, `{Name}SlotView.cs` | A dynamic list or grid. Several sources in one list add a header slot (`LIST-10`) |
| `{Screen}/{Name}BentoLayout.json` | The request says bento |
| `Services/{Feature}Config.cs` + its `.asset` | The feature has content data (`MODEL-12`) |
| `Services/{Feature}Installer.cs` | The feature binds anything (`DI-11`) |
| `Services/{Feature}Module.cs`, `I{Feature}Connector.cs`, `{Feature}Connector.cs` | The request names a backend |
| `Tests/{Name}ModelTests.cs` + `Tests/Client.{Feature}.Tests.asmdef` | The scope includes tests (`ASM-03`) |
| `{Screen}/{Name}.prefab` | The scope includes prefabs |
| `IMPLEMENTATION.md` | A person still has Unity work to do (`HAND-07`) |

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
