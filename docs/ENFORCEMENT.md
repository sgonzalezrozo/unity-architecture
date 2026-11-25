# Enforcement

The rules in `architecture/` say what must be true. Enforcement is the optional part that checks it automatically when an agent finishes. It's a separate package, so a project that installs only the rules gets none of it: `install.sh --enforcement` adds it in advisory mode, and `--enforce` makes a failed check block the stop.

## Modes

- **advisory** (the default): a failed check is reported, and the agent may finish. The mode is `AI_ENFORCEMENT`, else `.claude/enforcement.mode`.
- **enforce**: a failed check is sent back to the agent, and the stop is blocked, up to three attempts in a row.

## What runs

A Claude Code Stop hook stops an agent from finishing with a broken build. `templates/scripts/install.sh` installs it, as the [Setup Reference](../docs/REFERENCE.md#what-installsh-creates) shows. It runs only when `Assets`, `Packages` or `ProjectSettings` changed, sends failures back to the agent, and gives up after three attempts in a row.

Before compiling, it runs `scripts/check-feature.sh` on the folders the task is scoped to, the same ones whose tests run (`Logs/verify/test-scope`, `TEST-13`); with the whole project in scope, on the features this turn changed. Another task's unfinished feature never blocks the current one. It checks what a tool can check without Unity or a model, so it gives the same answer for any agent or model: the files against `Logs/ai/plan.md` (`CHK-01`), an installer exactly when the feature binds something (`CHK-03`), a spec for every `FromInstance` (`CHK-04`), the test assembly (`CHK-05`), the handoff's sections (`CHK-06`), namespaces (`CHK-07`), a `SectionedScroller` for a sectioned plan (`CHK-08`), file and screen folder names (`CHK-09`), warns about literal lists outside the mock (`CHK-10`), requires the files a feature always needs and keeps Views off injected data (`CHK-11`), warns about queries that build state (`CHK-12`), holds the plan to what was approved and to the scope the user chose (`CHK-13`), allows only files that are rows of the Feature files table (`CHK-14`), refuses bento layouts computed in C# (`CHK-15`), keeps `ScreenManager` in the screen's root Model and every screen it opens a `ScreenIds` constant (`CHK-16`), and refuses a feature's own `Forget` (`CHK-17`). Each failure names its rule, and counts as an attempt like a failed compile. Each session keeps its own test scope, plan, approved plan and attempts in `Logs/verify/session-<session>/`, so two sessions never check each other's work, and the scope the user chose is read from what the user typed and answered, never from tool output.

Compiling is quick, so the hook checks it on every stop. Which tests it runs depends on the task's scope (`TEST-13`):

| Scope | On every stop |
|---|---|
| "Solo codigo" (`code`) or code with prefabs (`code+prefabs`), as the user chose it (`TASK-01`) | Compiles and runs the feature checks. No Unity unit tests: no feature tests and no prefab validator, whatever the scope file says |
| Features: `Logs/verify/test-scope` names feature folders, and the scope has tests | Compiles, and runs the EditMode tests of those features and of every feature the change touched: the namespace `Client.{Feature}` (`ASM-03`) |
| The whole project: no scope file, or a change that can affect any feature (`Shared/`, `Client.asmdef`, `Client/Tests`, `Packages`, `ProjectSettings` or anything outside `Assets/Client`) | Compiles |

The hook never starts the full suite on its own: there's no periodic run. A full run is started by hand (`run_tests` with no filter), and the checklist reports it as not verified until someone runs it. The hook's message says which features' tests ran. The scope file can only add tests: the features a change touched are always tested, so naming the wrong folder never skips any. `tools/test-verify-hook.sh` checks these rules with a stub `verify.sh`.

A changed prefab under `Assets/Client` gets its feature's prefab validator case (`TEST-12`) on every stop, whatever the scope: the validator has one case per feature folder, `UnityArchitecture.Prefabs.Tests.ClientPrefabsTests.{Feature}` (`Root` for prefabs directly in `Assets/Client`). With the Editor open, the hook asks the agent to run it through `run_tests`; with it closed, `verify.sh` runs it with a filter. The tests related to a change (`TEST-11`) run on every change: with the Editor open through `run_tests` with a filter, and with it closed through `VERIFY_TEST_FILTER="<names or regex>" scripts/verify.sh`, which passes the filter to Unity's `-testFilter`.

| Editor | The hook runs | What it checks |
|---|---|---|
| Closed | `scripts/verify.sh` | Compiles in batch mode, with the tests the scope owes through `VERIFY_TEST_FILTER`: the features' tests (`^Client\.Inventory\.`) and the changed features' prefab validator cases. When the full suite is due, runs every EditMode test |
| Open | `scripts/verify-editor.sh` | Reads `Logs/verify/editor-compile.json`, `editor-tests-{Feature}.json`, `editor-prefabs-{Feature}.json` and `editor-tests.json`, written by the Editor. Asks the agent to compile (`refresh_unity`) when a script changed after the last compile, and to run (`run_tests`) a feature's tests (`group_names: ["^Client\\.Inventory\\."]`) or a prefab validator case that hasn't run since the feature changed. When the full suite is due, asks for every EditMode test. `VERIFY_TEST_FEATURES` names the features |

Both check Fast IoC's `GenerationStatus.json` and use the same exit codes: `0` passed, `1` failed, `2` couldn't run.


## Feature checks

`scripts/check-feature.sh` checks a feature folder without Unity or a model. The rule IDs it enforces:

| ID | Rule | Checks |
|---|---|---|
| `CHK-01` | `PLAN-02` | the files match Logs/ai/plan.md, when the plan is for this feature |
| `CHK-02` | `PLAN-02` | a change outside every feature (CHECK_OUTSIDE_CHANGED) is named in the plan's outside-feature |
| `CHK-03` | `DI-11` | an installer exactly when the feature binds something |
| `CHK-04` | `EDIT-14` | every FromInstance("X") has X.asset or X.asset.json in the feature |
| `CHK-05` | `ASM-03` | tests compile in Tests/Client.{Feature}.Tests.asmdef, and there is no .asmref |
| `CHK-06` | `HAND-07` | Views without prefabs come with an IMPLEMENTATION.md in the fixed sections |
| `CHK-07` | `naming` | every namespace is Client.{Feature} (Client.{Feature}.Tests in Tests/) |
| `CHK-08` | `LIST-10` | a plan with list: sectioned has a SectionedScroller |
| `CHK-09` | `TASK-05` | file names start with the feature's name; a single screen folder is {Feature}Main |
| `CHK-10` | `MODEL-12` | (warning) a list or array of literals outside the mock |
| `CHK-11` | `MODEL-13` | the files a feature always needs: a screen Model when there are Views, the slots and data of a list, the header slot of a sectioned list, the items Model and its source; Views read the screen Model, never an injected items Model, mock or Module (ROOT-06) |
| `CHK-12` | `MODEL-02` | (warning) a query that builds state the first time it's called |
| `CHK-13` | `PLAN-02` | the plan keeps what was approved: the same scope, decisions and files as the first plan of the turn; the scope the user chose (TASK-01), with no tests or prefabs it excludes; a bento layout needs a list |
| `CHK-14` | `TASK-05` | every file is a row of the Feature files table: no other types (an enum, a layout class...) |
| `CHK-15` | `LIST-08` | a bento layout is {Feature}BentoLayout.json, never tile positions computed in C# |
| `CHK-16` | `SCR-16` | only a screen's root Model calls ScreenManager: never a View, Controller, slot, items Model or mock; SCR-12   every screen it opens is a ScreenIds constant, never a string or a constant of its own: a screen that doesn't exist yet is an open question for the user |
| `CHK-17` | `async` | no Forget of the feature's own: ToolsCore.TaskExtensions (Tools Core package) is the one helper |
| `CHK-18` | `TASK-06` | a screen or prefab listed in project-facts.md (existing at session start) is still there |
