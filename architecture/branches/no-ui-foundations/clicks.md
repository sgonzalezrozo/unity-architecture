# Click Controllers without UI Foundations

Branch `no-ui-foundations` of the `input` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `input: no-ui-foundations`.

| Need | Form |
|---|---|
| Click input | `MonoBehaviour, IPointerClickHandler` |
| Raycast target | Transparent `Image` on the input GameObject |
| Disable clicks | Disable the input GameObject, or place it in an inactive state |

The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](../../mvc/where-a-model-lives.md).

```csharp
public class LoseLifeController : MonoBehaviour, IPointerClickHandler
{
    internal LivesModel livesModel;

    public void OnPointerClick(PointerEventData eventData)
    {
        livesModel.LoseLife();
    }
}
```
