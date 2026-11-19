# UI Tweens in MVC

DOTween-style tweens for UI, pooled and with no GC. In this architecture, **a View starts the tween when it reacts to a Model event** (`PREFAB-05`).

```csharp
private void RenderClaimed()
{
    claimedBadge.SetActive(trophyModel.IsClaimed);

    if (trophyModel.IsClaimed)
        uiContent.DOScale(Vector3.one, PUNCH_DURATION, EaseType.PunchOut);
}
```

- A press punch scales **`UI Content`**, never the `Action` (`PREFAB-17`).
- Cancel in `OnDisable` with `DoCancel()` so a late animation can't move something hidden.
- `IgnoreTimeScale()` for pause menus.
- Callbacks with **named methods**, not lambdas: `OnComplete(state, callback)` doesn't allocate.

> [!WARNING]
> The package README uses lambdas in its samples. Under `Assets/Client` they're forbidden (`UA0009`).
