# Menús y atajos: Screen System

| Menú | Para qué |
|---|---|
| **Tools > Screen System > Setup** | Crea los assets del proyecto, el backdrop de modales y las pantallas especiales. Repetirlo los repara |
| **Tools > Screen System > Documentation** | Abre la documentación |
| **Assets > Screen System > New Screen Feature** | Crea pantallas, listas para `GoTo`, en la carpeta donde haces clic derecho (la carpeta de la feature dentro de `Assets/Client`; su nombre prefija los IDs) |
| **Assets > Screen System > New Layer** | Crea un layer prefab en la carpeta seleccionada |

## En el Inspector

| Dónde | Botón |
|---|---|
| `ScreenManager` | **Create Special Screens**, **Open Screen Manager Window** (en Play: pila, qué se pinta, Back, Close All...) |
| `ScreenRegistry` | **Rebuild Registry from Assets** |
| `ScreenDefinition` | **Edit Prefab**, **Add Screen to Feature…** |

> [!TIP]
> Define `SCREEN_SYSTEM_VERBOSE` en los Scripting Define Symbols para ver logs informativos.

> [!WARNING] Agente con MCP
> En lugar de los menús, el agente llama `ScreenAuthoring.CreateScreen`, `ScreenAuthoring.CreateLayer` y `SpecialScreensCreator.Create()` (`SCR-13`, `SCR-15`, `EDIT-13`).
