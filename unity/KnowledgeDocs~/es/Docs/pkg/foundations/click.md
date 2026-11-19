# UI Foundations: click Controller

`BaseClickController` es un **raycast target invisible** con un override `OnClick()`. Al ser un `Graphic`, el `Action` no necesita `Image`.

```csharp
public class LoseLifeController : BaseClickController
{
    private LivesModel livesModel;

    private void Awake()
    {
        livesModel = GetComponentInParent<LivesModel>();
    }

    protected override void OnClick()
    {
        livesModel.LoseLife();
    }
}
```

> [!RULE] OPT-02
> Con UI Foundations instalado, todo click Controller deriva de `BaseClickController`. Los de drag siguen con `IDrag*`.

- `Interactable = false` desactiva clicks y raycasts.
- Si limpia en `OnDestroy`: `protected override void OnDestroy()` y llama `base.OnDestroy()`.
- `Client.asmdef` referencia `UIFoundations`.
