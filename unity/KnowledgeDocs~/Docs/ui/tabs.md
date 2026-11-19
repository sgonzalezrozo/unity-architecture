# Tabs

Tab content is **static**: nested in the prefab at edit time, never instantiated at runtime.

```text
InventoryScreen
├── Tabs
│   ├── WeaponsTab [InventoryTabView]
│   │   ├── UI Content
│   │   │   ├── ActiveRoot
│   │   │   └── InactiveRoot
│   │   └── Action (Image: alpha 0) [SelectTabController]
│   └── ArmorTab (same components, another serialized enum)
└── Content [TabContentView]
    ├── WeaponsContent (CanvasGroup)
    └── ArmorContent (CanvasGroup)
```

- **One Model** holds the selected tab, preferably as an enum.
- Every tab shares **one View class and one Controller class**; a serialized enum picks the tab.
- Hide tabs with `CanvasGroup` (`alpha`, `interactable`, `blocksRaycasts`) so their Views stay subscribed. `SetActive` only when a hidden tab is expensive.
- Expensive content loads when its tab opens (`PERF-01`).

<!-- if: com.sgonzalezrozo.ui-scroller -->
> [!TIP]
> If the tabs only **filter one list**, they need no prefabs of their own: see the [Inventory example](doc:examples.inventory).
<!-- endif -->
