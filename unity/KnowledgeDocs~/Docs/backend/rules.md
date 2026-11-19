# Backend data rules

| ID | Rule |
|---|---|
| `BE-01` | Backend data is **not mutated**. To apply a change, replace the entry with the backend's response |
| `BE-02` | Timestamps in **Unix seconds**; time left is computed when read |
| `BE-03` | Each operation has a state a View can render. An empty list is a valid result, not a failure |
| `BE-04` | Prevent concurrent loads with the state itself: `return` if already loading |
| `BE-05` | A cancelled operation is **not** a failure: restore the previous state and log no error |

```csharp
public enum TrophyLoadState { Idle, Loading, Loaded, Failed }

public async Task LoadTrophiesAsync(CancellationToken cancellationToken)
{
    if (loadState == TrophyLoadState.Loading)
        return;
    // ...
}
```

> [!DONT]
> `trophy.isClaimed = true;` after claiming. Replace the trophy with the one the server returns.
