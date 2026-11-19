# Screen System: navegación

```csharp
ScreenManager screens = await ScreenManager.WhenReadyAsync();
await screens.SetRoot(ScreenIds.ShopMain);    // primera pantalla
await screens.GoTo(ScreenIds.ShopDetail);     // apila otra
await screens.GoBack();                       // vuelve (también Escape)
```

| ID | Regla |
|---|---|
| `SCR-01` | Se abre y cierra **solo** con `ScreenManager`: nada de `SetActive`, instanciar o cargar escenas para UI |
| `SCR-06` | El boot hace `await ScreenManager.WhenReadyAsync()` antes del primer `SetRoot` |
| `SCR-07` | Las llamadas devuelven `NavigationResult`; una llamada durante otra se ignora (`Transitioning`) |
| `SCR-08` | Pasa de qué trata la navegación con `GoTo(screen, value)`; se recibe con `IScreenParameter<T>` |
| `SCR-12` | Usa las constantes generadas `ScreenIds`, nunca strings |

> [!TIP] Tab bar
> Un layer compartido cuyos botones llaman `GoTo(tab, NavigationHistory.ClearToRoot)`, así back vuelve a la raíz.
