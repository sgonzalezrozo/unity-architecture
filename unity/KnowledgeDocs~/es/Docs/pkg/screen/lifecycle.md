# Screen System: mostrar y ocultar

> [!RULE] SCR-05
> El trabajo al mostrar u ocultar usa `IScreenShow` / `IScreenHide` (o `IScreenLifecycle`). Los layers ocultos **siguen activos**: `OnEnable` y `OnDisable` no corren.

```csharp
public class MainRoomLoadController : MonoBehaviour, IScreenShow
{
    internal TrophyRoomModule trophyRoomModule;

    private readonly CancellationTokenSource destroyCancellation = new();

    public void OnScreenShown()
    {
        trophyRoomModule.LoadTrophiesAsync(destroyCancellation.Token).Forget("TrophyRoom.Load");
    }

    private void OnDestroy()
    {
        destroyCancellation.Cancel();
        destroyCancellation.Dispose();
    }
}
```

| ID | Regla |
|---|---|
| `SCR-02` | No toques `Canvas.sortingOrder`: el package lo pone |
| `SCR-03` | No descargues pantallas ni liberes sus handles: un cambio de escena lo hace |
| `SCR-10` | Sin API de transiciones: la intro arranca en `OnScreenShown()`; la outro se reproduce **antes** de llamar `GoTo` |
