# A prefab's JSON spec

It lists the **whole hierarchy, in order**: nothing is added that it doesn't name.

```json
{
  "name": "ClaimTrophyBanner",
  "components": ["ClaimTrophyBannerModel", "ClaimTrophyBannerView"],
  "fields": { "labelText": "UI Content/Label" },
  "children": [
    {
      "type": "uiContent",
      "children": [
        { "type": "background", "color": [0.1, 0.1, 0.2, 1] },
        { "type": "text", "name": "Label", "text": "Claim your trophy" },
        { "type": "image", "name": "Icon", "layout": { "anchor": [0, 0.5], "size": [96, 96], "position": [16, 0] } }
      ]
    },
    { "type": "action", "controller": "ClaimTrophyController" }
  ]
}
```

| Field | Meaning |
|---|---|
| `type` | `container`, `background`, `visuals`, `uiContent`, `image`, `text`, `action` or `prefab` |
| `components` | Classes in the `Client` assembly and Unity UI components |
| `fields` | Serialized fields and the path of the object each points to (`"."` = itself) |
| `controller` | An `action`'s Controller |
| `layout` | `"stretch"` (default) or `anchor`, `size`, `position`, `pivot` |
| `ignoreLayout` | `true` for overlays inside a layout group |
| `prefab` | A nested prefab's path |

> [!WARNING]
> The spec can't express gradients, sprites, font size or alignment yet: they're reported and set by hand afterwards.
