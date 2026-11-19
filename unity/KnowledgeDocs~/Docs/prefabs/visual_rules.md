# Visual prefab rules

| ID | Rule |
|---|---|
| `PREFAB-02` | What fills its container uses **stretch** anchors (0,0 to 1,1). Fixed size uses a point anchor. No fractional anchors (0.2 to 0.8) |
| `PREFAB-03` | With dynamic content, the **pivot** points where it grows: Y `1` if it grows down |
| `PREFAB-04` | Text is always `TextMeshProUGUI`, never `UnityEngine.UI.Text`. Fixed sprites and fonts are set in the prefab, not through a View field |
| `PREFAB-05` | No `Animator` or `Animation` in UI: motion is a **tween** a View starts |
| `PREFAB-07` | Rectangular clipping uses `RectMask2D`, not `Mask` |
| `PREFAB-08` | A container filled at runtime is **empty** in the prefab |
| `PREFAB-12` | Anything that animates or changes often gets its own nested `Canvas` |
| `PREFAB-13` | At most about **5 levels** under the root |
