# Crear un elemento de UI

El camino para cualquier pantalla, botón o panel:

```flow
Model con tests -> View raíz -> Controller en Action -> Prefab con UI Content -> Validar:verde
```

1. [**Model**](doc:model.que_es): el estado y los comandos, con tests primero. Vive en la raíz del scope.
1. [**View raíz**](doc:view.forma): se suscribe en `OnEnable`, pinta con `Render{Algo}`, máximo 5 campos serializados.
1. [**Controller**](doc:controller.action): un hijo llamado `Action` con una `Image` alpha 0; un input, un comando.
1. [**Prefab**](doc:prefabs.forma): lo que toca el dedo dentro de `UI Content`; el `Action` es el último hijo.
1. [**Validar**](doc:prefabs.validador): **Tools > Unity Architecture > Validate Client Prefabs**.

```text
ClaimBanner [ClaimBannerModel, ClaimBannerView]
├── UI Content
│   ├── Background (Image, raycast on)
│   └── Label (TextMeshProUGUI, raycast off)
└── Action (Image: alpha 0) [ClaimController]
```

| Para... | Mira |
|---|---|
| Varios aspectos (cargando, error) | [Estados visuales](doc:ui.estados_visuales) |
| Pestañas | [Pestañas](doc:ui.tabs) |
<!-- if: com.sgonzalezrozo.ui-scroller -->
| Listas | [UI Scroller: una lista](doc:pkg.scroller.lista) |
<!-- else -->
| Listas | [Lista sin UI Scroller](doc:ui.lista_sin_scroller) |
<!-- endif -->
| Toggle o Slider propios | [Ejemplo Settings](doc:ejemplos.settings) |
<!-- if: com.coplaydev.unity-mcp -->
| Que el agente lo construya | [Armado de UI con MCP](doc:mcp.armado_ui) |
<!-- endif -->
