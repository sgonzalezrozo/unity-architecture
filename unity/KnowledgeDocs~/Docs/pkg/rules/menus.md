# Menus and shortcuts: Unity Architecture

| Menu | For |
|---|---|
| **Tools > Unity Architecture > Rules Guide** | This window |
| **Tools > Unity Architecture > Validate Client Prefabs** | Validates every prefab under `Assets/Client` and lists each error with its rule |
| **Assets > Unity Architecture > Build Prefab From Spec** | Builds, validates and compares a prefab from the selected JSON spec |

## From code or the command line

| Call | For |
|---|---|
| `PrefabValidator.ValidateAsset(path)` | Validate one prefab |
| `PrefabSpecs.BuildFromSpec(json, path)` | Build a prefab from a spec |
| `PrefabSpecs.Compare(json, path)` | Differences between spec and prefab |
| `-executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine` | Validator in batch mode (exit `1` on errors) |

## Project scripts

```bash
scripts/verify.sh
```

```bash
VERIFY_TEST_FILTER="TrophyRoomModuleTests" scripts/verify.sh
```

```bash
bash .ai/templates/scripts/update.sh
```
