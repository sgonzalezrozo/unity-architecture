# Build a UI element

The path for any screen, button or panel:

```flow
Model with tests -> Root View -> Controller on Action -> Prefab with UI Content -> Validate:green
```

1. [**Model**](doc:model.what_is_a_model): state and commands, tests first. It lives on the scope root.
1. [**Root View**](doc:view.shape): subscribes in `OnEnable`, renders with `Render{Subject}`, 5 serialized fields at most.
1. [**Controller**](doc:controller.action): a child named `Action` with an alpha 0 `Image`; one input, one command.
1. [**Prefab**](doc:prefabs.shape): what the finger touches goes inside `UI Content`; `Action` is the last child.
1. [**Validate**](doc:prefabs.validator): **Tools > Unity Architecture > Validate Client Prefabs**.

```text
ClaimBanner [ClaimBannerModel, ClaimBannerView]
├── UI Content
│   ├── Background (Image, raycast on)
│   └── Label (TextMeshProUGUI, raycast off)
└── Action (Image: alpha 0) [ClaimController]
```

| For... | See |
|---|---|
| Several looks (loading, error) | [Visual states](doc:ui.visual_states) |
| Tabs | [Tabs](doc:ui.tabs) |
<!-- if: com.sgonzalezrozo.ui-scroller -->
| Lists | [UI Scroller: a list](doc:pkg.scroller.list) |
<!-- else -->
| Lists | [A list without UI Scroller](doc:ui.list_without_scroller) |
<!-- endif -->
| Your own Toggle or Slider | [Settings example](doc:examples.settings) |
<!-- if: com.coplaydev.unity-mcp -->
| Having the agent build it | [Building UI with MCP](doc:mcp.ui_building) |
<!-- endif -->
