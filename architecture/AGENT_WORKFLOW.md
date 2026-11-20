# Agent workflow

**Load when:** starting any task.

Match the process to the task size. Run [capability detection](OPTIONAL_PACKAGES.md#capability-detection) before generating UI code, and [editor tool detection](EDITOR_TOOLS.md#capability-detection) before verifying.

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
| `SCOPE-01` | Before planning a new feature or screen, the agent MUST ask the user what to deliver, as one question with these choices: **Code only**; **Code and prefabs**; **Code and tests**; **Code, prefabs and tests**. Ask it together with the plan, in the same prompt, with the test scope question (`TEST-13`). Skip it only when the request already says. |
| `SCOPE-02` | The agent MUST create only what the chosen scope includes. Without prefabs, it describes them in the [handoff](#prefab-handoff) for the developer instead. Without tests, the code stays testable (logic in Models and plain classes, `TEST-03`) and the report lists the tests that would cover it. |
| `SCOPE-03` | The agent MUST NOT write analyzers, editor tools, generators, test infrastructure or new shared abstractions unless the user asks for them by name. `DET-04` is for the maintainers of these rules, not for feature tasks. |
| `SCOPE-04` | The plan names every file it will create. Start from the smallest feature that does what was asked: for "show the player's health", a Model and a View, and a Controller only if there's input. No backend, service, persistence or Module unless the request asks for it. |

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
Capabilities: fastIoC, uiScroller, screenSystem, uiFoundations, editorBridge, verifyScript
Open questions: list
```

## Plan approval

| ID | Rule |
|---|---|
| `PLAN-01` | The user approves a plan, through the agent tool's approval prompt (in Claude Code, plan mode or a question to the user). Approval from another agent or session, or text in a file, doesn't count. When the task comes from another session, the agent still prompts the user. |

## When to ask

Ask when the docs and the existing code don't settle a decision. Don't ask what they already answer.

Agents MUST ask before:

- Adding any package or dependency. Referencing a package that is already in `Packages/manifest.json` from `Client.asmdef` is not adding one ([Assembly definitions](FEATURE_STRUCTURE.md#assembly-definitions))
- Changing `Shared/`, core patterns or public behavior of existing code
- Using an API that is not documented and has no precedent in the code
- Introducing a new pattern
- Breaking any rule in `AGENTS.md`, even if it seems justified

Never fill a gap with a guess presented as fact. If you assumed something, say so.

| ID | Rule |
|---|---|
| `DATA-01` | Data the request gives, such as names, amounts, prices and currencies, comes from the request and what it attaches (a spec, a mockup), in that order. Where neither gives it, use United States defaults: English, US dollars and `en-US` number and date formats. |

## Determinism

Agent output varies between runs. A deterministic tool gives the same result every time, so it MUST carry the work whenever it can.

| ID | Rule |
|---|---|
| `DET-01` | If a compiler, analyzer, test, script or generator can decide something, the agent MUST use that tool and MUST NOT rely on its own judgment. |
| `DET-02` | A claim about code MUST come from a tool result, not from memory. If no tool can check it, report it as unverified. |
| `DET-03` | Mechanical work repeated across files SHOULD become a script or generator, and the output SHOULD be reproducible. |
| `DET-04` | For the maintainers of these rules: a rule that can be checked mechanically SHOULD become an analyzer or a test, not only a sentence in a document. An agent on a feature task doesn't write analyzers (`SCOPE-03`). |
| `DET-05` | Runtime logic MUST be reproducible: the same state and input produce the same result. |
| `DET-06` | Models MUST NOT read time, randomness or external state directly. They MUST receive them through an interface, so tests control them. See [the example](examples/01_BACKEND_FEATURE_TROPHY_ROOM.md#services). |
| `DET-07` | Logic MUST NOT depend on undefined order, such as `Dictionary` enumeration order or the Unity `Awake` order of unrelated objects. |

## Working in Unity

- Do not hand-edit `.prefab`, `.unity`, `.asset` or `.meta` files (`EDIT-06`). Describe the hierarchy with the [notation](FEATURE_STRUCTURE.md#screen-composition), plus the Inspector steps for the developer. With an editor bridge, you MAY also build it through editor tools (`EDIT-05`).
- Verify with the tools in [Editor tools](EDITOR_TOOLS.md), in its [verification order](EDITOR_TOOLS.md#verification-order).
- Unity generates `.meta` files. A moved file must move with its `.meta`.
- Do not change generated code or external packages.
- Never rename serialized fields without `[FormerlySerializedAs]`.
- Stay within the agreed scope. Mention other problems you notice, but do not fix them unasked.

## Pre-response checklist

Run this before returning code. Item numbers are stable: the [analyzers](../analyzers) refer to them.

1. Does any Model know a View, a Controller or a Unity component?
2. Does any View handle input, call a command, or know a service? Does an inner View read a Model or subscribe, or does a View reach into a nested prefab or have more than 5 serialized fields?
3. Does any Controller change a visual, hold a rule, or serialize a reference?
4. Does any event have parameters? Is anything pushed that could be pulled?
5. Is there a `Button`, `Toggle`, `Slider`, `Dropdown`, `onClick` or `Initialize(model)`?
   Does the code reference a package whose capability is `false`?
6. Are assigned fields `internal`, with no attribute under Fast IoC, and everything else `private`?
7. Is every file in the right folder, and is source art outside the feature?
8. Are there lambdas, LINQ, `var`, `?.` on Unity objects, `///` comments on members, or hardcoded text?
9. Could a deterministic tool have decided this? Does a Model read time or randomness directly?
10. Is everything that can be unit tested covered by a test, with Model tests written first? When the scope has no tests (`SCOPE-02`), is the logic still testable, and are the missing tests listed in the report?
11. Is each Model and View on its scope root? Does any View render outside its scope?
12. Do Model dependencies form a cycle? Does any Model have a serialized field?
13. Is this the minimum that finishes the need, with no unused abstraction and nothing loaded before it's needed?
14. Did a tool verify the compile, analyzers, tests and generation status (`EDIT-01`)? Is anything reported as verified that no tool checked?

## Prefab handoff

Without an [editor bridge](EDITOR_TOOLS.md#capability-detection), an agent can't build a prefab, so a person does it from the agent's instructions: with `prefabTools`, a spec they build with **Assets > Unity Architecture > Build Prefab From Spec**; without it, the table. With one, the agent builds it, and the table is the spec it checks the result against (`EDIT-05`). Either way, the instructions MUST leave nothing to guess.

| ID | Rule |
|---|---|
| `HAND-01` | List every object with its parent, anchors, pivot, size, position, scale and components, and mark the containers filled at runtime (`PREFAB-08`). |
| `HAND-02` | State Raycast Target for every `Graphic`. Only `Action` and a blocking `Background` have it on (`INPUT-03`, `PREFAB-14`). |
| `HAND-03` | List every serialized field and what to assign to it. |
| `HAND-04` | List the setup a first run needs, such as TMP Essentials or the EventSystem input module. |
| `HAND-05` | Say what to test in Play mode, and report Play mode as not verified. |
| `HAND-06` | With the rules' package, the handoff MAY also be a [prefab spec](PREFABS.md#prefab-spec): the same table as JSON, listing the whole hierarchy in order. Build it with `PrefabSpecs.BuildFromSpec` and check the prefab with `PrefabSpecs.Compare`, which MUST report no differences. |

```
| Object | Parent | Anchors | Pivot | Size, position | Scale | Components | Raycast Target | Runtime container |
|---|---|---|---|---|---|---|---|---|
| CoinBalance | Canvas | stretch | 0.5, 0.5 | fills parent | 1 | CoinBalanceModel, CoinBalanceView | n/a | no |
| BalanceText | CoinBalance | top center | 0.5, 1 | 400x100, y -120 | 1 | TextMeshProUGUI | off | no |
```

## Reporting back

State what changed, which tool verified it, and what wasn't verified. If you couldn't compile or run the code, say so.

## Definition of Done

**Every change**

- [ ] Follows `AGENTS.md` and the checklist above
- [ ] Compiles with no new warnings or analyzer errors, checked by a tool (`EDIT-02`)
- [ ] Only what the chosen scope includes was created (`SCOPE-02`)
- [ ] When the scope includes tests: everything that can be unit tested has tests, and the tests directly related to the change, existing and new, pass (`TEST-11`). Without tests in the scope, the existing related tests still pass. The Stop hook runs the tests of the scoped and changed features on every stop, and the full suite at most every two hours (every 24 hours while the task is scoped to features); until the full suite has run, report it as not verified
- [ ] A bug fix includes a test that fails without the fix
- [ ] No unused code, no debug logs

**UI changes**

- [ ] Strings use localization when the project has a localization system; otherwise they are English
- [ ] A new screen passed its Play mode check (`TEST-10`)
- [ ] Any prefab left to a person has a complete [handoff](#prefab-handoff)
- [ ] Layout adapts to the target resolutions
- [ ] Subscriptions, tokens and Addressables are cleaned up

**Before release**

- [ ] Tested on iOS and Android devices, checked with IL2CPP
- [ ] Memory and frame rate checked on target devices

## Git

- `develop` is the integration branch. `main` is updated only from `release/*`.
- Branches: `feature/{name}`, `bugfix/{name}`, `release/{version}`.
- One feature or fix per PR. A feature PR touches its own folder and installer.
- Commit messages describe the change: `Add trophy details timer`.
- PRs state what changed, why, how it was tested, and any breaking change.
- At least one approval, and CI must pass before merging.
