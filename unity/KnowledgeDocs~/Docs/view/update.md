# Update en una View

> [!RULE] VIEW-06
> Una View solo usa `Update()` para valores que cambian con el tiempo (una cuenta atrás), y **con throttling**.

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
> El tiempo restante lo calcula el Model desde un timestamp Unix y un `IClock` (`BE-02`, `DET-06`). La View solo lo pinta.
