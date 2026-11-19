# Async calls and network

> [!RULE] BE-06
> Only **Controllers** start async commands, with `.Forget("Context")` and a `CancellationToken` they own.

> [!RULE] BE-07
> The Controller cancels and disposes its token source in `OnDestroy`.

<!-- if: com.sgonzalezrozo.screen-system -->
```csharp
public class MainRoomLoadController : MonoBehaviour, IScreenShow
{
    internal TrophyRoomModule trophyRoomModule;

    private readonly CancellationTokenSource destroyCancellation = new();

    public void OnScreenShown()
    {
        trophyRoomModule.LoadTrophiesAsync(destroyCancellation.Token).Forget("TrophyRoom.LoadTrophies");
    }

    private void OnDestroy()
    {
        destroyCancellation.Cancel();
        destroyCancellation.Dispose();
    }
}
```
<!-- else -->
```csharp
public class MainRoomLoadController : MonoBehaviour
{
    internal TrophyRoomModule trophyRoomModule;

    private readonly CancellationTokenSource destroyCancellation = new();

    private void OnEnable()
    {
        trophyRoomModule.LoadTrophiesAsync(destroyCancellation.Token).Forget("TrophyRoom.LoadTrophies");
    }

    private void OnDestroy()
    {
        destroyCancellation.Cancel();
        destroyCancellation.Dispose();
    }
}
```
<!-- endif -->

<!-- if: com.sgonzalezrozo.screen-system -->
- The load starts in `OnScreenShown()`, **never** in `Start()`: a screen can be shown more than once.
<!-- else -->
- The load starts in the screen root's `OnEnable`, **never** in `Start()`: a screen can be shown more than once.
<!-- endif -->
- **15 s** timeout per attempt, **3 attempts** at most, exponential backoff with jitter in one shared helper.
- Show that something is happening during long operations, and allow cancelling them.

> [!WARNING] Not specified yet
> Real-time updates (WebSocket, polling), caching, batching and rate limiting have no agreed pattern: **ask**.
