# Ejemplo: feature con backend (Trophy Room)

Dos pantallas comparten un **Module**. `MainRoom` lista trofeos; `DetailsTrophy` muestra el seleccionado con cuenta atrás y un botón de reclamar.

```text
Assets/Client/TrophyRoom/
├── MainRoom/          MainRoom.prefab, TrophySlot.prefab, MainRoomLoadController,
│                      MainRoomStateView, TrophyListView, TrophyScroller,
│                      TrophySlotModel, TrophySlotView, SelectTrophyController
├── DetailsTrophy/     DetailsTrophy.prefab, DetailsTrophyView, ClaimAreaView,
│                      ClaimTrophyController
└── Services/          TrophyRoomModule, TrophyData, ITrophyRoomConnector,
                       TrophyRoomConnector, IClock, SystemClock, TrophyRoomInstaller
```

| Pieza | Por qué así |
|---|---|
| `TrophyRoomModule` inyectado | Dos pantallas lo comparten sin padre común (fila 2) |
| `IClock` | El Module no lee la hora directamente: los tests la controlan |
| `TrophyLoadState` enum | `Idle`, `Loading`, `Loaded`, `Failed`: la View pinta cada uno |
| Reclamar reemplaza el trofeo | Nunca se pone `isClaimed = true` local (`BE-01`) |
| La carga en `OnScreenShown()` | Una pantalla puede mostrarse más de una vez |

> [!TIP]
> Léelo completo con el icono de documento de esta tarjeta.
