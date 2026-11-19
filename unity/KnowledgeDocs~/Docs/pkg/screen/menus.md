# Menus and shortcuts: Screen System

| Menu | For |
|---|---|
| **Tools > Screen System > Setup** | Creates the project assets, the modal backdrop and the special screens. Running it again repairs them |
| **Tools > Screen System > Documentation** | Opens the documentation |
| **Assets > Screen System > New Screen Feature** | Creates a feature with its screens, ready for `GoTo` (right-click `Assets/Client`) |
| **Assets > Screen System > New Layer** | Creates a layer prefab in the selected folder |

## In the Inspector

| Where | Button |
|---|---|
| `ScreenManager` | **Create Special Screens**, **Open Screen Manager Window** (in Play mode: the stack, what's rendering, Back, Close All...) |
| `ScreenRegistry` | **Rebuild Registry from Assets** |
| `ScreenDefinition` | **Edit Prefab**, **Add Screen to Feature…** |

> [!TIP]
> Define `SCREEN_SYSTEM_VERBOSE` in Scripting Define Symbols to see informational logs.

> [!WARNING] Agents with MCP
> Instead of the menus, the agent calls `ScreenAuthoring.CreateScreen`, `ScreenAuthoring.CreateLayer` and `SpecialScreensCreator.Create()` (`SCR-13`, `SCR-15`, `EDIT-13`).
