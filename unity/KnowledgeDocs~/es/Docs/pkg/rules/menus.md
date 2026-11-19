# Menús y atajos: Unity Architecture

| Menú | Para qué |
|---|---|
| **Tools > Unity Architecture > Rules Guide** | Esta ventana |
| **Tools > Unity Architecture > Validate Client Prefabs** | Valida todos los prefabs de `Assets/Client` y lista cada error con su regla |
| **Assets > Unity Architecture > Build Prefab From Spec** | Construye, valida y compara un prefab desde el spec JSON seleccionado |

## Desde código o línea de comandos

| Llamada | Para qué |
|---|---|
| `PrefabValidator.ValidateAsset(path)` | Valida un prefab |
| `PrefabSpecs.BuildFromSpec(json, path)` | Construye un prefab desde un spec |
| `PrefabSpecs.Compare(json, path)` | Diferencias entre spec y prefab |
| `-executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine` | Validador en batch (exit `1` si hay errores) |

## Scripts del proyecto

```bash
scripts/verify.sh
```

```bash
VERIFY_TEST_FILTER="TrophyRoomModuleTests" scripts/verify.sh
```

```bash
bash .ai/templates/scripts/update.sh
```
