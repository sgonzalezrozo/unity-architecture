# Naming types and objects

| Type | Pattern | Example |
|---|---|---|
| Screen Model | `{Screen}Model` | `EditRoomModel` |
| Feature Module | `{Feature}Module` | `TrophyRoomModule` |
| View | `{Name}View` | `TrophySlotView` |
| Controller | `{Action}Controller` | `ClaimTrophyController` |
| Input GameObject | Always `Action` | `Action` |
| State root | `{State}Root` | `LoadingRoot` |
| Rendering method | `Render{Subject}` | `RenderTrophyName` |
| Data | `{Name}Data` | `TrophyData` |
| Connector | `I{Feature}Connector` | `ITrophyRoomConnector` |
| Installer | `{Feature}Installer` | `TrophyRoomInstaller` |
| Prefab | Same as its main element | `TrophySlot.prefab` |

- **Namespace:** `Client.{Feature}`, flat for the whole feature.
- Folder names have **no** spaces.
