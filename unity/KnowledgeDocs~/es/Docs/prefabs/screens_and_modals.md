# Pantallas y modales

> [!RULE] PREFAB-10
> Una pantalla o layer: raíz stretch, un `Background` opcional y un `Content` dentro del safe area. Sin Screen System, se oculta apagando su `Canvas`. `CanvasGroup` solo para fades e interacción.

> [!RULE] PREFAB-11
> Un modal bloquea lo de detrás. Cerrar al tocar fuera es un `Action` entre el `Background` y la `Window`, con un `CloseController`; la `Window` bloquea con su propio `Background`.

```text
ConfirmModal
├── Background (Image, oscurece, raycast on)
├── Action (Image: alpha 0) [CloseController]
└── Window
    ├── Background (Image, raycast on)
    └── Content
```
