# The Action object

> [!RULE] INPUT-01
> The Controller sits on a dedicated child named **`Action`**, separate from the visuals. With several actions, every one is still `Action`: its parent's name tells them apart.

```text
CloseButton
├── UI Content
│   └── Visuals
│       ├── Background (Image, raycast on)
│       └── Label (TextMeshProUGUI, raycast off)
└── Action (Image: alpha 0, raycast on) [CloseController]
```

| ID | Rule |
|---|---|
| `INPUT-02` | `Action` has its own raycast target that fills the element, and is the **last sibling** |
| `INPUT-03` | Visual-only graphics have `raycastTarget` **off** (except a blocking `Background`) |
| `INPUT-04` | In a multi-state element, `Action` sits inside the state that accepts input |
| `INPUT-05` | A screen-level Controller handles only lifecycle events, never a child's input |
