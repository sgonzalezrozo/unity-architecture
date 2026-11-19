# El objeto Action

> [!RULE] INPUT-01
> El Controller va en un hijo dedicado llamado **`Action`**, separado de los visuales. Con varias acciones, todas se llaman `Action`: el nombre del padre las distingue.

```text
CloseButton
├── UI Content
│   └── Visuals
│       ├── Background (Image, raycast on)
│       └── Label (TextMeshProUGUI, raycast off)
└── Action (Image: alpha 0, raycast on) [CloseController]
```

| ID | Regla |
|---|---|
| `INPUT-02` | `Action` tiene su propio raycast que llena el elemento y es el **último hermano** |
| `INPUT-03` | Los gráficos solo visuales tienen `raycastTarget` **off** (salvo un `Background` que bloquea) |
| `INPUT-04` | En un elemento con estados, `Action` va dentro del estado que acepta input |
| `INPUT-05` | Un Controller de pantalla solo maneja eventos de ciclo de vida, nunca input de un hijo |
