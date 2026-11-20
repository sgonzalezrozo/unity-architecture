# Tabs

Tab content is static: nested in the prefab at edit time, never instantiated at runtime. Expensive content SHOULD load when its tab opens (`PERF-01`).

```
InventoryScreen
├── Tabs
│   ├── WeaponsTab [InventoryTabView]
│   │   ├── UI Content
│   │   │   ├── ActiveRoot
│   │   │   └── InactiveRoot
│   │   └── Action (Image: alpha 0) [SelectTabController]
│   └── ArmorTab (same components, different serialized tab)
└── Content [TabContentView]
    ├── WeaponsContent (CanvasGroup)
    └── ArmorContent (CanvasGroup)
```

- One Model MUST hold the selected tab, preferably as an enum.
- Tab elements MUST share one View class and one Controller class. A serialized enum selects the tab.
- Each tab has its own prefab, nested in the screen.
- Hide tabs with `CanvasGroup` (`alpha`, `interactable`, `blocksRaycasts`) so their Views stay subscribed. Use `SetActive` when a hidden tab is expensive.
- Tabs that filter one list need no separate prefabs: see [Filtered list](../examples/03_FILTERED_LIST_INVENTORY.md).
