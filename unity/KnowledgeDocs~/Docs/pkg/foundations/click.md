# UI Foundations: click Controller

`BaseClickController` is an **invisible raycast target** with an `OnClick()` override. Since it's a `Graphic`, the `Action` needs no `Image`.

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
> With UI Foundations installed, every click Controller derives from `BaseClickController`. Drag Controllers keep `IDrag*`.

- `Interactable = false` turns off clicks and raycasts.
- If it cleans up in `OnDestroy`: `protected override void OnDestroy()` and call `base.OnDestroy()`.
- `Client.asmdef` references `UIFoundations`.
