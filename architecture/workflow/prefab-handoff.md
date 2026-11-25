# Prefab handoff

A person builds a prefab when the task's scope excludes prefabs (`TASK-02`), or when it includes them but there's no [editor bridge](../EDITOR_TOOLS.md#editor-capabilities). Then the agent writes the instructions: with `prefabTools`, a spec they build with **Assets > Unity Architecture > Build Prefab From Spec**; without it, the table. With a bridge and prefabs in scope, the agent builds it, and the table is the spec it checks the result against (`EDIT-05`). Either way, the instructions MUST leave nothing to guess.

| ID | Rule |
|---|---|
| `HAND-01` | List every object with its parent, anchors, pivot, size, position, scale and components, and mark the containers filled at runtime (`PREFAB-08`). |
| `HAND-02` | State Raycast Target for every `Graphic`. Only `Action` and a blocking `Background` have it on (`INPUT-03`, `PREFAB-14`). |
| `HAND-03` | List every serialized field and what to assign to it. |
| `HAND-04` | List the setup a first run needs, such as TMP Essentials or the EventSystem input module. |
| `HAND-05` | Say what to test in Play mode, and report Play mode as not verified. |
| `HAND-06` | With the rules' package, the handoff MAY also be a [prefab spec](../PREFABS.md#prefab-spec): the same table as JSON, listing the whole hierarchy in order. Build it with `PrefabSpecs.BuildFromSpec` and check the prefab with `PrefabSpecs.Compare`, which MUST report no differences. |
| `HAND-07` | When a person still has Unity work to do (prefabs, Inspector assignments, scene objects, first-run setup), the agent MUST write the whole handoff to `Assets/Client/{Feature}/IMPLEMENTATION.md` (`FEAT-02`), in the [form](#implementationmd) below, and save any prefab spec (`HAND-06`) beside it. The final response MUST link that file and MUST NOT repeat the setup. With no Unity work left, no file is written. |

```
| Object | Parent | Anchors | Pivot | Size, position | Scale | Components | Raycast Target | Runtime container |
|---|---|---|---|---|---|---|---|---|
| CoinBalance | Canvas | stretch | 0.5, 0.5 | fills parent | 1 | CoinBalanceModel, CoinBalanceView | n/a | no |
| BalanceText | CoinBalance | top center | 0.5, 1 | 400x100, y -120 | 1 | TextMeshProUGUI | off | no |
```

## IMPLEMENTATION.md

The same sections, in this order, every time. Leave a section out only when it has nothing.

```
# {Feature}: implementation

## Code
One line per file created or changed, with its role (Model, View, Controller, Scroller, Installer, data, config).

## Assets to create
Only assets without a spec. A data asset with a spec (EDIT-14) is built by the tool: name the spec and whether
it was built, so the person knows whether to run Build Asset From Spec.

## Prefabs
Per prefab: the hierarchy (FEATURE_STRUCTURE notation), then the handoff table (HAND-01, HAND-02).

## Inspector assignments
Every serialized field and what to assign to it (HAND-03), including UI Scroller settings such as Slot Prefab,
Layout and Layout JSON.

## First run
Scene, installer scene name, TMP Essentials, EventSystem (HAND-04).

## Play mode check
What to check, reported as not verified (HAND-05).
```
