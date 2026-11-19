# Nombres de tipos y objetos

| Tipo | Patrón | Ejemplo |
|---|---|---|
| Model de pantalla | `{Screen}Model` | `EditRoomModel` |
| Module de feature | `{Feature}Module` | `TrophyRoomModule` |
| View | `{Name}View` | `TrophySlotView` |
| Controller | `{Action}Controller` | `ClaimTrophyController` |
| GameObject de input | Siempre `Action` | `Action` |
| Raíz de estado | `{State}Root` | `LoadingRoot` |
| Método de pintado | `Render{Subject}` | `RenderTrophyName` |
| Datos | `{Name}Data` | `TrophyData` |
| Connector | `I{Feature}Connector` | `ITrophyRoomConnector` |
| Installer | `{Feature}Installer` | `TrophyRoomInstaller` |
| Prefab | Igual que su elemento principal | `TrophySlot.prefab` |

- **Namespace:** `Client.{Feature}`, plano para toda la feature.
- Las carpetas **no** llevan espacios.
