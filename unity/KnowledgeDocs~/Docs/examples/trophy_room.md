# Example: backend feature (Trophy Room)

Two screens share one **Module**. `MainRoom` lists trophies; `DetailsTrophy` shows the selected one with a countdown and a claim button.

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

| Piece | Why |
|---|---|
| `TrophyRoomModule` is injected | Two screens share it with no common parent (row 2) |
| `IClock` | The Module doesn't read the time directly: tests control it |
| `TrophyLoadState` enum | `Idle`, `Loading`, `Loaded`, `Failed`: the View renders each |
| Claiming replaces the trophy | `isClaimed = true` is never set locally (`BE-01`) |
| The load in `OnScreenShown()` | A screen can be shown more than once |

> [!TIP]
> Read it in full with this card's document icon.
