# Visual states

Use for two or more mutually exclusive looks of one element, such as Loading, Loaded and Failed.

```
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

| ID | Rule |
|---|---|
| `STATE-01` | The Model MUST expose the state, preferably as an enum. |
| `STATE-02` | The View MUST render every root from that state in one method. The code depends on the `input` fork below. |
| `STATE-03` | One state set per concern. Nest them if needed. |
| `STATE-04` | A View inside an inactive root is disabled, so it MUST read the Model again in `OnEnable`. |
| `STATE-05` | To show or hide one element, use `CanvasGroup` or the View's own logic. |

> **Fork `input`** · how the View renders the state. Open only the branch the [profile](../OPTIONAL_PACKAGES.md#the-profile) names:
> - `ui-foundations`: [UI Foundations: visual state View](../branches/ui-foundations/visual-states.md)
> - `no-ui-foundations`: [Visual state View without UI Foundations](../branches/no-ui-foundations/visual-states.md)
