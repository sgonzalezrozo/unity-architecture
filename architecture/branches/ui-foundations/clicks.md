# UI Foundations: click Controllers

Branch `ui-foundations` of the `input` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `input: ui-foundations`.

| Need | Form |
|---|---|
| Click input | Subclass of `BaseClickController` |
| Raycast target | `BaseClickController`, a transparent `Graphic` |
| Disable clicks | `Interactable = false` |

Every click Controller on an `Action` derives from `BaseClickController` (`OPT-02`). The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](../../mvc/where-a-model-lives.md).

```csharp
public class LoseLifeController : BaseClickController
{
    internal LivesModel livesModel;

    protected override void OnClick()
    {
        livesModel.LoseLife();
    }
}
```

`BaseClickController` derives from `Graphic`, so a Controller that cleans up in `OnDestroy` MUST use `protected override void OnDestroy()` and call `base.OnDestroy()`.

Verify before use: `BaseClickController`.
