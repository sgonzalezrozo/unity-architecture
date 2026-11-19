# Screens and modals

> [!RULE] PREFAB-10
> A screen or layer: a stretch root, an optional `Background`, and a `Content` inside the safe area. Without Screen System, hide it by turning off its `Canvas`. `CanvasGroup` is only for fades and interaction.

> [!RULE] PREFAB-11
> A modal blocks what's behind it. Closing on a tap outside is an `Action` between the `Background` and the `Window`, with a `CloseController`; the `Window` blocks touches with its own `Background`.

```text
ConfirmModal
├── Background (Image, dims, raycast on)
├── Action (Image: alpha 0) [CloseController]
└── Window
    ├── Background (Image, raycast on)
    └── Content
```
