# Prefab handoff

Without an [editor bridge](../EDITOR_TOOLS.md#editor-capabilities), an agent can't build a prefab, so a person does it from the agent's instructions: with `prefabTools`, a spec they build with **Assets > Unity Architecture > Build Prefab From Spec**; without it, the table. With one, the agent builds it, and the table is the spec it checks the result against (`EDIT-05`). Either way, the instructions MUST leave nothing to guess.

| ID | Rule |
|---|---|
| `HAND-01` | List every object with its parent, anchors, pivot, size, position, scale and components, and mark the containers filled at runtime (`PREFAB-08`). |
| `HAND-02` | State Raycast Target for every `Graphic`. Only `Action` and a blocking `Background` have it on (`INPUT-03`, `PREFAB-14`). |
| `HAND-03` | List every serialized field and what to assign to it. |
| `HAND-04` | List the setup a first run needs, such as TMP Essentials or the EventSystem input module. |
| `HAND-05` | Say what to test in Play mode, and report Play mode as not verified. |
| `HAND-06` | With the rules' package, the handoff MAY also be a [prefab spec](../PREFABS.md#prefab-spec): the same table as JSON, listing the whole hierarchy in order. Build it with `PrefabSpecs.BuildFromSpec` and check the prefab with `PrefabSpecs.Compare`, which MUST report no differences. |

```
| Object | Parent | Anchors | Pivot | Size, position | Scale | Components | Raycast Target | Runtime container |
|---|---|---|---|---|---|---|---|---|
| CoinBalance | Canvas | stretch | 0.5, 0.5 | fills parent | 1 | CoinBalanceModel, CoinBalanceView | n/a | no |
| BalanceText | CoinBalance | top center | 0.5, 1 | 400x100, y -120 | 1 | TextMeshProUGUI | off | no |
```
