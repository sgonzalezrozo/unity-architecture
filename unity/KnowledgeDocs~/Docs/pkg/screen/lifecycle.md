# Screen System: show and hide

> [!RULE] SCR-05
> Work that runs when a screen shows or hides uses `IScreenShow` / `IScreenHide` (or `IScreenLifecycle`). Hidden layers **stay active**: `OnEnable` and `OnDisable` don't run.

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

| ID | Rule |
|---|---|
| `SCR-02` | Don't touch `Canvas.sortingOrder`: the package sets it |
| `SCR-03` | Don't unload screens or release their handles: a scene change does it |
| `SCR-10` | No transition API: the intro starts in `OnScreenShown()`; the outro plays **before** calling `GoTo` |
