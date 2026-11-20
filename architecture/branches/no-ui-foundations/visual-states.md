# Visual state View without UI Foundations

Branch `no-ui-foundations` of the `input` fork. Read it only when the [profile](../../OPTIONAL_PACKAGES.md#the-profile) says `input: no-ui-foundations`.

Mutually exclusive looks are one `GameObject` root per state, and the View activates the one that matches. The `internal` field shows an injected Model. Otherwise, use `GetComponentInParent`: see [Where a Model lives](../../mvc/where-a-model-lives.md).

```csharp
public class PurchaseStateView : MonoBehaviour
{
    [SerializeField] private GameObject availableRoot;
    [SerializeField] private GameObject lockedRoot;
    [SerializeField] private GameObject ownedRoot;

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
        PurchaseState state = storeModel.SelectedItemState;

        availableRoot.SetActive(state == PurchaseState.Available);
        lockedRoot.SetActive(state == PurchaseState.Locked);
        ownedRoot.SetActive(state == PurchaseState.Owned);
    }
}
```
