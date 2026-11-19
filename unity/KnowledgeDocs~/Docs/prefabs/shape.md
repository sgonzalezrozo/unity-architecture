# The shape of a prefab

```text
QuitGameAlert                 root: Model and root View, scale 1, rotation 0
├── Background                raycast on: blocks what's under it
├── Title (TextMeshProUGUI)
├── Cancel
│   ├── UI Content            everything the Action hits
│   │   ├── Background        raycast on: it has an Action
│   │   └── Text (TextMeshProUGUI)
│   └── Action                Image alpha 0, last child [CancelController]
└── Quit
    └── Container             a parent in between changes no name
        ├── UI Content
        └── Action [QuitController]
```

- Each prefab is **one scope** with one root View on its root.
- Every input object is named `Action`; its only sibling is `UI Content`.

> [!RULE] PREFAB-01
> The root has scale `(1,1,1)` and rotation `0`. A visual scale or rotation goes on a `Visuals` child.

> [!RULE] PREFAB-17
> Everything the `Action` hits is wrapped in **`UI Content`**. A press tween scales `UI Content`; the `Action` stays still, so its hit area doesn't change under the finger.

**See also:** [The Action object](doc:controller.action) · [Input and raycast](doc:prefabs.input_and_raycast) · [Validate prefabs](doc:prefabs.validator)
