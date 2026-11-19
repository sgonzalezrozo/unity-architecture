# Screen System: navigation

```csharp
ScreenManager screens = await ScreenManager.WhenReadyAsync();
await screens.SetRoot(ScreenIds.ShopMain);    // first screen
await screens.GoTo(ScreenIds.ShopDetail);     // push another
await screens.GoBack();                       // back (Escape does it too)
```

| ID | Rule |
|---|---|
| `SCR-01` | Screens open and close **only** through `ScreenManager`: no `SetActive`, instantiating or loading scenes for UI |
| `SCR-06` | Boot code awaits `ScreenManager.WhenReadyAsync()` before the first `SetRoot` |
| `SCR-07` | Calls return `NavigationResult`; a call during another is ignored (`Transitioning`) |
| `SCR-08` | Pass what the navigation is about with `GoTo(screen, value)`; receive it with `IScreenParameter<T>` |
| `SCR-12` | Use the generated `ScreenIds` constants, never strings |

> [!TIP] Tab bar
> A shared layer whose buttons call `GoTo(tab, NavigationHistory.ClearToRoot)`, so back returns to the root.
