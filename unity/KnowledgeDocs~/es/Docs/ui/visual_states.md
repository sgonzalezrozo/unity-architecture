# Estados visuales

Para dos o más aspectos excluyentes de un elemento: Cargando, Cargado, Error...

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

| ID | Regla |
|---|---|
| `STATE-01` | El Model expone el estado, mejor como **enum** |
| `STATE-02` | La View pinta todas las raíces desde ese estado en **un método** |
| `STATE-03` | Un set de estados por concepto; anídalos si hace falta |
| `STATE-04` | Una View dentro de una raíz inactiva vuelve a leer el Model en `OnEnable` |
| `STATE-05` | Para mostrar/ocultar un solo elemento: `CanvasGroup` o la lógica de la View |
