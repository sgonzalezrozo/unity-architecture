# Build prefabs with recipes

`UnityArchitecture.Prefabs.PrefabRecipes` builds the standard pieces already following the rules. A prefab is a list of calls, not values set by hand.

| Recipe | Builds |
|---|---|
| `CreateRoot` | A stretch root, scale 1, with its Model and View |
| `CreateScreenRoot` | Root + blocking `Background` + `Content` |
| `CreateModalRoot` | Dimming background, optional close `Action`, and `Window` |
| `CreateSlotRoot` | A fixed-size list slot |
| `AddUIContent` | The `UI Content` that wraps what the `Action` hits |
| `AddAction` | `Action`, last, with an invisible `Image` |
| `AddStateRoots` | One `{State}Root` per state |
| `AddNestedPrefab` | An instance of another prefab (still its own scope) |
| `SaveAndValidate` | Saves and returns the validator's result |

> [!NOTE] JSON spec
> `PrefabSpecs.BuildFromSpec(json, path)` builds a prefab from JSON and `PrefabSpecs.Compare(json, path)` lists the differences. The same spec always builds the same prefab. Without a Unity MCP, **Assets > Unity Architecture > Build Prefab From Spec** does it from the selected spec.
