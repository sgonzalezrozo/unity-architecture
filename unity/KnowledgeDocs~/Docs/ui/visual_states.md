# Visual states

For two or more mutually exclusive looks of one element: Loading, Loaded, Failed...

```text
PurchaseArea [PurchaseStateView]
├── AvailableRoot
│   ├── UI Content
│   │   └── PriceText (TextMeshProUGUI)
│   └── Action (Image: alpha 0) [BuyController]
├── LockedRoot
│   └── LockIcon (Image)
└── OwnedRoot
    └── OwnedBadge (Image)
```

```csharp
private void RenderPurchaseState()
{
    PurchaseState state = storeModel.SelectedItemState;

    availableRoot.SetActive(state == PurchaseState.Available);
    lockedRoot.SetActive(state == PurchaseState.Locked);
    ownedRoot.SetActive(state == PurchaseState.Owned);
}
```

| ID | Rule |
|---|---|
| `STATE-01` | The Model exposes the state, preferably as an **enum** |
| `STATE-02` | The View renders every root from that state in **one method** |
| `STATE-03` | One state set per concern; nest them if needed |
| `STATE-04` | A View inside an inactive root reads the Model again in `OnEnable` |
| `STATE-05` | To show or hide one element: `CanvasGroup` or the View's own logic |
