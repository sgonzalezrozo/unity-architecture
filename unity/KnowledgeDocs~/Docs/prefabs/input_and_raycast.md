# Input and raycast in prefabs

| ID | Rule |
|---|---|
| `PREFAB-06` | No persistent `UnityEvent` listeners or `EventTrigger`: all input goes through a Controller |
| `PREFAB-09` | `Action` has an `Image` with **alpha 0** and **Cull Transparent Mesh** on: it draws nothing and costs no overdraw |
| `PREFAB-14` | The `Background` of an element with an `Action` has raycast **on**. So does a screen's, but not each layer's |
| `PREFAB-15` | Every serialized reference is **assigned** in the prefab |
| `PREFAB-16` | Inside a layout group, `Background`, `Action` and overlays get a `LayoutElement` with **Ignore Layout** |

<!-- if: com.sgonzalezrozo.ui-foundations -->
> [!TIP]
> With UI Foundations, the Controller (`BaseClickController`) **is** the graphic: the `Action` needs no `Image`.
<!-- endif -->
