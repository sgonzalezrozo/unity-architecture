# UI Foundations: ViewStateMachine

Shows **one look at a time** from a list (locked, available, owned), by name or index, with an instant or fade transition.

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

> [!IMPORTANT]
> Each state needs a `CanvasGroup`, and state names match the enum values **exactly**.
