# Construir un prefab desde execute_code

```csharp
// execute_code no tiene usings: nombra los tipos completos.
string json = System.IO.File.ReadAllText("Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.json");
string prefab = "Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.prefab";
var built = UnityArchitecture.Prefabs.PrefabSpecs.BuildFromSpec(json, prefab);
var checkedAgain = UnityArchitecture.Prefabs.PrefabValidator.ValidateAsset(prefab);
var differences = UnityArchitecture.Prefabs.PrefabSpecs.Compare(json, prefab);
```

| Llamada | Devuelve |
|---|---|
| `BuildFromSpec(json, path)` | `List<PrefabViolation>` del validador; vacía si pasa |
| `ValidateAsset(path)` | `List<PrefabViolation>` (`RuleId`, `ObjectPath`, `Message`, `IsWarning`) |
| `Compare(json, path)` | `List<string>` de diferencias; vacía si coinciden |

## Cambiar un prefab

- **Con spec:** edita el JSON y reconstruye. Un cambio hecho a mano aparece como diferencia en `Compare`, así el spec sigue siendo la fuente de verdad.
- **Sin spec:** `PrefabUtility.LoadPrefabContents`, cambia con `PrefabRecipes` y guarda.
