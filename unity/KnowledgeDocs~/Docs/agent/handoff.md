# Prefab handoff

Without MCP, the agent can't build a prefab: a person builds it from its instructions (or from a spec with **Build Prefab From Spec**). With MCP, the table is the spec the result is checked against. Either way, it **leaves nothing to guess**.

| ID | Includes |
|---|---|
| `HAND-01` | Every object with parent, anchors, pivot, size, position, scale and components; which containers fill at runtime |
| `HAND-02` | Raycast Target for every `Graphic` (only `Action` and a blocking `Background` on) |
| `HAND-03` | Every serialized field and what to assign to it |
| `HAND-04` | First-run setup (TMP Essentials, the EventSystem input module) |
| `HAND-05` | What to test in Play mode (reported as not verified) |

```text
| Object | Parent | Anchors | Pivot | Size, position | Scale | Components | Raycast | Runtime |
|---|---|---|---|---|---|---|---|---|
| CoinBalance | Canvas | stretch | 0.5, 0.5 | fills parent | 1 | CoinBalanceModel, CoinBalanceView | n/a | no |
| BalanceText | CoinBalance | top center | 0.5, 1 | 400x100, y -120 | 1 | TextMeshProUGUI | off | no |
```
