# UI Foundations: ViewStateMachine

Muestra **un aspecto a la vez** de una lista (bloqueado, disponible, comprado), por nombre o índice, con transición instantánea o fade.

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
> Cada estado necesita un `CanvasGroup`, y los nombres de estado coinciden **exactamente** con los valores del enum.
