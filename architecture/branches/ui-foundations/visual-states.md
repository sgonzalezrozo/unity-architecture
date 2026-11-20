# UI Foundations: visual state View

Branch `ui-foundations` of the `input` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `input: ui-foundations`.

Mutually exclusive looks render through `ViewStateMachine.SetState(stateName)`. The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](../../mvc/where-a-model-lives.md).

```csharp
public class PurchaseStateView : MonoBehaviour
{
    [SerializeField] private ViewStateMachine purchaseStateMachine;

    internal StoreModel storeModel;

    private void OnEnable()
    {
        storeModel.OnSelectedItemStateChanged += RenderPurchaseState;
        RenderPurchaseState();
    }

    private void OnDisable()
    {
        storeModel.OnSelectedItemStateChanged -= RenderPurchaseState;
    }

    private void RenderPurchaseState()
    {
        purchaseStateMachine.SetState(storeModel.SelectedItemState.ToString());
    }
}
```

Each state in `ViewStateMachine` needs a `CanvasGroup`. State names MUST match the enum values exactly.

Verify before use: `ViewStateMachine`.
