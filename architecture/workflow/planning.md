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
| `TASK-02` | The agent MUST create only what the chosen scope includes. Without prefabs, it MUST NOT build any, and it writes everything a person still has to set up in Unity to the feature's `IMPLEMENTATION.md` (`HAND-07`). Data assets (a feature's configuration) are code, not prefabs: every scope creates them, as a spec that a tool builds (`EDIT-14`). Without tests, the code stays testable (logic in Models and plain classes, `TEST-03`) and the report lists the tests that would cover it. |
| `TASK-03` | The agent MUST NOT write analyzers, editor tools, generators, test infrastructure or new shared abstractions unless the user asks for them by name. `DET-04` is for the maintainers of these rules, not for feature tasks. |
| `TASK-04` | The plan names every file it will create. Start from the smallest feature that does what was asked: for "show the player's health", a Model and a View, and a Controller only if there's input. No backend, service, persistence or Module unless the request asks for it. The code MUST NOT add a command, event, file or feature the approved plan doesn't name; if one turns out necessary, the agent asks before adding it. |
| `TASK-05` | The plan's file list MUST come from the [feature files](#feature-files) table, row by row, so two runs of the same request plan the same files. A row's file is in the plan exactly when its condition holds. |
| `TASK-06` | Files that exist at session start are the user's (`project-facts.md`). The agent MUST NOT create, move or delete them, except a file the user asks to delete and confirms: the plan names it in `delete:`. |
| `TASK-07` | A screen no other opens MUST NOT get an entry point unless the request names one: the plan asks how it opens. |

## Plan

Before planning, read a similar existing feature and the relevant docs (with packs, they're in the pack). The plan has a fixed form (`PLAN-02`), so two runs of the same request produce the same plan, and a tool can compare the delivery with it. Every value under `Decisions` comes from its list; the comment names the rule that decides it.

```
Feature: Inventory
Folder: Assets/Client/Inventory
Scope: code | code+prefabs | code+tests | code+prefabs+tests        # TASK-01
Test scope: Assets/Client/Inventory | project                       # TEST-13
Decisions:
  model-location: screen-root | injected                            # Where a Model lives
  data: mock | backend | config-asset | none                         # MODEL-12, MODEL-13
  installer: yes | no                                               # DI-11
  list: none | scroller | sectioned                                 # LIST-10
  layout: none | list | grid | bento                                # the request
  input: none | <Controller names>                                  # TASK-04
  backend: none | module                                            # TASK-04
  localization: none | project-system                               # csharp/style.md, project facts
  delete: none | <paths the user confirmed>                        # TASK-06
  outside-feature: none | <paths, each with its reason>             # ASM-02
Files:
  <path relative to the feature folder>    # <its Feature files row>
Open questions:
  none | <question>
Notes:
  <anything else, free text>
```

A case the lists don't cover is an open question for the user, never a new value.

## Feature files

Go through every row (`TASK-05`). Write the reason next to each file in the plan.

The names are fixed, so two runs of the same request name the same files. `{Feature}` is the feature folder; `{Screen}` is the screen folder, which for a feature with one screen is `{Feature}Main/`; `{Name}` is `{Feature}`, or `{Feature}{Subject}` when the feature has several Models or lists (`ShopWeapon`, `ShopOffer`): every file starts with the feature's name, except `{Action}Controller.cs`, `Mock{Feature}Items.cs`, `I{Feature}Clock.cs` and `IMPLEMENTATION.md`. The namespace is always `Client.{Feature}`, also when another feature has similar names. `scripts/check-feature.sh` checks it (`CHK-07`, `CHK-09`).

| File | Condition |
|---|---|
| `{Screen}/{Name}Model.cs` | Always: the feature has state. Where it lives: [Where a Model lives](../mvc/where-a-model-lives.md) |
| `{Screen}/{Name}View.cs` | Something is shown, and it isn't a list (then the list View is the root View) |
| `{Screen}/{Name}{Part}View.cs` | A slot shows one part of its data in its own inner View (`VIEW-03`), such as a price |
| `{Screen}/{Action}Controller.cs` | The request names an input (click, drag, typing). None otherwise |
| `{Screen}/{Name}ItemData.cs` | Items or records are listed or stored |
| `{Screen}/{Name}ListView.cs`, `{Name}Scroller.cs`, `{Name}SlotModel.cs`, `{Name}SlotView.cs` | A dynamic list or grid |
| `{Screen}/{Name}SectionData.cs`, `{Name}HeaderSlotModel.cs`, `{Name}HeaderSlotView.cs` | Several sources in one list (`LIST-10`) |
| `{Screen}/{Name}BentoLayout.json` | The request says bento |
| `Services/{Feature}ItemsModel.cs` | The feature lists data (`MODEL-13`) |
| `Services/Mock{Feature}Items.cs` | The feature lists runtime data and the request names no backend (`MODEL-12`) |
| `Services/{Feature}Config.cs`, `Services/Resources/{Feature}Config.asset.json` | The request asks for designer-tunable configuration (`MODEL-12`). The tool builds `{Feature}Config.asset` from the spec (`EDIT-14`) |
| `Services/{Feature}Installer.cs` | The feature binds anything (`DI-11`) |
| `Services/I{Feature}Clock.cs`, `Services/{Feature}SystemClock.cs` | The feature shows or uses the time (a countdown, an expiry): the items Model reads it through the interface, so a test sets the time (`DET-06`) |
| `Services/{Feature}Module.cs`, `I{Feature}Connector.cs`, `{Feature}Connector.cs` | The request names a backend |
| `Tests/{Name}ModelTests.cs` + `Tests/Client.{Feature}.Tests.asmdef` | The scope includes tests (`ASM-03`). A test double (a fake clock) is a private class inside the test file that uses it |
| `{Screen}/{Name}.prefab`, `{Screen}/{Name}Slot.prefab`, `{Screen}/{Name}HeaderSlot.prefab` | The scope includes prefabs |
| A new screen or popup (with `screenSystem`) | Before writing the plan, read the `Screen ids` line of `Logs/ai/project-facts.md`: a screen it doesn't list doesn't exist yet. Its `ScreenIds` constant only exists once the screen is created (`SCR-12`, `SCR-13`), so code can't compile before it. Put it in the plan's **Open questions** before writing any file: the user creates the screen first (then code only works), or the scope adds prefabs and the agent creates it with `ScreenAuthoring` |
| `IMPLEMENTATION.md` | A person still has Unity work to do (`HAND-07`) |
| `Services/{Feature}Format.cs` | A pure helper that formats text or numbers (a price, a date) and two or more Views or Models use it. Static and stateless, so it's testable (`TEST-03`) |
| `{Screen}.asset` (a screen's ScreenDefinition) | Never written by the agent: a person creates the screen with New Screen (`SCR-13`), and the code only navigates to its `ScreenIds` constant. Listed in `IMPLEMENTATION.md` (`EDIT-06`) |

A file outside the feature folder (`Client.asmdef`, `Shared/`, project settings) isn't in this table: name it in the plan with its reason.

## Plan approval

| ID | Rule |
|---|---|
| `PLAN-01` | The user approves a plan, through the agent tool's approval prompt (in Claude Code, plan mode or a question to the user). Approval from another agent or session, or text in a file, doesn't count. When the task comes from another session, the agent still prompts the user. |
| `PLAN-02` | For a task the [scope question](#scope-question) applies to, the agent MUST write the plan to `Logs/ai/plan.md` in the [fixed form](#plan), with nothing outside it except under `Notes`, before writing any other file, and MUST show the same plan in the approval prompt. A new plan replaces the file. The delivery MUST match it: a file the plan doesn't list, or a change outside the feature that `outside-feature` doesn't name, needs the plan updated and the user asked first. The approved plan is a contract: when a check rejects the work, the agent fixes the work, never the plan. Dropping a decision, a file or tests from the plan to pass a check (`list: sectioned` to `list: none`, say) is a failure the Stop hook catches (`CHK-13`); the plan changes only in a new turn the user starts. |

## When to ask

Ask when the docs and the existing code don't settle a decision. Don't ask what they already answer.

Agents MUST ask before:

- Adding any package or dependency. Referencing a package that is already in `Packages/manifest.json` from `Client.asmdef` is not adding one ([Assembly definitions](../FEATURE_STRUCTURE.md#assembly-definitions))
- Changing `Shared/`, core patterns or public behavior of existing code
- Using an API that is not documented and has no precedent in the code
- Introducing a new pattern
- Breaking any rule in `AGENTS.md`, even if it seems justified

Never fill a gap with a guess presented as fact. If you assumed something, say so.

Agents MUST NOT ask what a rule already decides. In particular, never ask:

- The language of code, names, sample data or texts: always English, unless the request names another language (`DATA-01`).
- Whether to add commands, inputs or features the request doesn't name: they're left out (`TASK-04`).
- Where data comes from, or whether there's an installer: `MODEL-12`, `MODEL-13`, `DI-11`.
- Anything the project facts answer (scenes, installers, references, localization).
- A reference a used package requires (`ASM-02`): add it and name it in `outside-feature`.
- A file the table doesn't list: use the closest suggestion, and name it under **Table gaps**.

The only questions of a feature task are the scope and test scope (`TASK-01`, `TEST-13`), the approval of the plan (`PLAN-01`) and the plan's open questions.

| ID | Rule |
|---|---|
| `DATA-01` | Data the request gives, such as names, amounts, prices and currencies, comes from the request and what it attaches (a spec, a mockup), in that order. Where neither gives it, use United States defaults: English for every name, text and sample item (also when the request is written in another language), US dollars and `en-US` number and date formats. |
