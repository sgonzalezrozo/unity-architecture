# Crear un elemento de UI

El camino para cualquier pantalla, botón o panel:

```flow
Model con tests -> View raíz -> Controller en Action -> Prefab con UI Content -> Validar:verde
```

1. [**Model**](doc:model.what_is_a_model): el estado y los comandos, con tests primero. Vive en la raíz del scope.
1. [**View raíz**](doc:view.shape): se suscribe en `OnEnable`, pinta con `Render{Algo}`, máximo 5 campos serializados.
1. [**Controller**](doc:controller.action): un hijo llamado `Action` con una `Image` alpha 0; un input, un comando.
1. [**Prefab**](doc:prefabs.shape): lo que toca el dedo dentro de `UI Content`; el `Action` es el último hijo.
1. [**Validar**](doc:prefabs.validator): **Tools > Unity Architecture > Validate Client Prefabs**.

```text
ClaimBanner [ClaimBannerModel, ClaimBannerView]
├── UI Content
│   ├── Background (Image, raycast on)
│   └── Label (TextMeshProUGUI, raycast off)
└── Action (Image: alpha 0) [ClaimController]
```

| Para... | Mira |
|---|---|
| Varios aspectos (cargando, error) | [Estados visuales](doc:ui.visual_states) |
| Pestañas | [Pestañas](doc:ui.tabs) |
<!-- if: com.sgonzalezrozo.ui-scroller -->
| Listas | [UI Scroller: una lista](doc:pkg.scroller.list) |
<!-- else -->
| Listas | [Lista sin UI Scroller](doc:ui.list_without_scroller) |
<!-- endif -->
| Toggle o Slider propios | [Ejemplo Settings](doc:examples.settings) |
<!-- if: com.coplaydev.unity-mcp -->
| Que el agente lo construya | [Armado de UI con MCP](doc:mcp.ui_building) |
<!-- endif -->
