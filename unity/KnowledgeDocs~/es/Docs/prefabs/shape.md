# La forma de un prefab

```text
QuitGameAlert                 raíz: Model y View raíz, escala 1, rotación 0
├── Background                raycast on: bloquea lo de debajo
├── Title (TextMeshProUGUI)
├── Cancel
│   ├── UI Content            todo lo que golpea el Action
│   │   ├── Background        raycast on: tiene un Action
│   │   └── Text (TextMeshProUGUI)
│   └── Action                Image alpha 0, último hijo [CancelController]
└── Quit
    └── Container             un padre intermedio no cambia ningún nombre
        ├── UI Content
        └── Action [QuitController]
```

- Cada prefab es **un scope** con una View raíz en su raíz.
- Todo objeto de input se llama `Action`; su único hermano es `UI Content`.

> [!RULE] PREFAB-01
> La raíz tiene escala `(1,1,1)` y rotación `0`. Una escala o rotación visual va en un hijo `Visuals`.

> [!RULE] PREFAB-17
> Todo lo que golpea el `Action` va envuelto en **`UI Content`**. El tween de pulsación escala `UI Content`; el `Action` se queda quieto y su área no cambia bajo el dedo.

**Ver también:** [El objeto Action](doc:controller.action) · [Input y raycast](doc:prefabs.input_and_raycast) · [Validar prefabs](doc:prefabs.validator)
