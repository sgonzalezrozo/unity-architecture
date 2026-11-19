# Build a prefab from execute_code

```csharp
// execute_code has no using directives: name the types in full.
string json = System.IO.File.ReadAllText("Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.json");
string prefab = "Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.prefab";
var built = UnityArchitecture.Prefabs.PrefabSpecs.BuildFromSpec(json, prefab);
var checkedAgain = UnityArchitecture.Prefabs.PrefabValidator.ValidateAsset(prefab);
var differences = UnityArchitecture.Prefabs.PrefabSpecs.Compare(json, prefab);
```

| Call | Returns |
|---|---|
| `BuildFromSpec(json, path)` | The validator's `List<PrefabViolation>`; empty when it passes |
| `ValidateAsset(path)` | `List<PrefabViolation>` (`RuleId`, `ObjectPath`, `Message`, `IsWarning`) |
| `Compare(json, path)` | `List<string>` of differences; empty when they match |

## Changing a prefab

- **With a spec:** edit the JSON and rebuild. A change made by hand shows up as a difference in `Compare`, so the spec stays the source of truth.
- **Without a spec:** `PrefabUtility.LoadPrefabContents`, change it with `PrefabRecipes`, and save.
