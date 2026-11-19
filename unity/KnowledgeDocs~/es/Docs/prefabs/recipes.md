# Construir prefabs con recetas

`UnityArchitecture.Prefabs.PrefabRecipes` construye las piezas estándar ya cumpliendo las reglas. Un prefab es una lista de llamadas, no valores puestos a mano.

| Receta | Construye |
|---|---|
| `CreateRoot` | Raíz stretch, escala 1, con su Model y View |
| `CreateScreenRoot` | Raíz + `Background` que bloquea + `Content` |
| `CreateModalRoot` | Fondo oscuro, `Action` de cerrar opcional y `Window` |
| `CreateSlotRoot` | Slot de lista de tamaño fijo |
| `AddUIContent` | El `UI Content` que envuelve lo que golpea el `Action` |
| `AddAction` | `Action`, último, con `Image` invisible |
| `AddStateRoots` | Un `{State}Root` por estado |
| `AddNestedPrefab` | Instancia de otro prefab (sigue siendo su scope) |
| `SaveAndValidate` | Guarda y devuelve el resultado del validador |

> [!NOTE] Spec JSON
> `PrefabSpecs.BuildFromSpec(json, path)` construye un prefab desde un JSON y `PrefabSpecs.Compare(json, path)` lista las diferencias. El mismo spec siempre da el mismo prefab. Sin un MCP de Unity, **Assets > Unity Architecture > Build Prefab From Spec** lo hace desde el spec seleccionado.
