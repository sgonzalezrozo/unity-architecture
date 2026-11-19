# Pestañas (tabs)

El contenido de las pestañas es **estático**: anidado en el prefab al editar, nunca instanciado en runtime.

```text
InventoryScreen
├── Tabs
│   ├── WeaponsTab [InventoryTabView]
│   │   ├── UI Content
│   │   │   ├── ActiveRoot
│   │   │   └── InactiveRoot
│   │   └── Action (Image: alpha 0) [SelectTabController]
│   └── ArmorTab (mismos componentes, otro enum serializado)
└── Content [TabContentView]
    ├── WeaponsContent (CanvasGroup)
    └── ArmorContent (CanvasGroup)
```

- **Un Model** guarda la pestaña seleccionada, mejor como enum.
- Todas las pestañas comparten **una clase View y una clase Controller**; un enum serializado elige la pestaña.
- Oculta con `CanvasGroup` (`alpha`, `interactable`, `blocksRaycasts`) para que sus Views sigan suscritas. `SetActive` solo si la pestaña oculta es cara.
- Lo caro se carga al abrir su pestaña (`PERF-01`).

<!-- if: com.sgonzalezrozo.ui-scroller -->
> [!TIP]
> Si las pestañas solo **filtran una lista**, no necesitan prefabs propios: mira el ejemplo **Inventario**.
<!-- endif -->
