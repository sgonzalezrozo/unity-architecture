# UI Tweens en MVC

Tweens estilo DOTween para UI, con entidades reutilizadas y sin GC. En esta arquitectura, el tween lo lanza **una View al reaccionar a un evento del Model** (`PREFAB-05`).

```csharp
private void RenderClaimed()
{
    claimedBadge.SetActive(trophyModel.IsClaimed);

    if (trophyModel.IsClaimed)
        uiContent.DOScale(Vector3.one, PUNCH_DURATION, EaseType.PunchOut);
}
```

- La pulsación (punch) escala **`UI Content`**, nunca el `Action` (`PREFAB-17`).
- Cancela en `OnDisable` con `DoCancel()` para que una animación tardía no mueva algo oculto.
- `IgnoreTimeScale()` para menús de pausa.
- Callbacks con **métodos con nombre**, no lambdas: `OnComplete(state, callback)` no asigna memoria.

> [!WARNING]
> El README del package usa lambdas en sus ejemplos. En `Assets/Client` están prohibidas (`UA0009`).
