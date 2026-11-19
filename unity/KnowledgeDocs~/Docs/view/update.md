# Update in a View

> [!RULE] VIEW-06
> A View uses `Update()` only for values that change with time (a countdown), and **throttled**.

```csharp
private const float COUNTDOWN_RENDER_INTERVAL_SECONDS = 1f;

private float nextCountdownRenderTime;

private void Update()
{
    if (Time.unscaledTime < nextCountdownRenderTime)
        return;

    nextCountdownRenderTime = Time.unscaledTime + COUNTDOWN_RENDER_INTERVAL_SECONDS;
    RenderCountdown();
}
```

> [!NOTE]
> The Model computes the time left from a Unix timestamp and an `IClock` (`BE-02`, `DET-06`). The View only renders it.
