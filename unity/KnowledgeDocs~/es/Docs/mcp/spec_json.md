# El spec JSON de un prefab

Lista la jerarquía **completa y en orden**: no se añade nada que no nombre.

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

| Campo | Significa |
|---|---|
| `type` | `container`, `background`, `visuals`, `uiContent`, `image`, `text`, `action` o `prefab` |
| `components` | Clases del assembly `Client` y componentes de UI de Unity |
| `fields` | Campos serializados y la ruta del objeto al que apuntan (`"."` = él mismo) |
| `controller` | El Controller de un `action` |
| `layout` | `"stretch"` (por defecto) o `anchor`, `size`, `position`, `pivot` |
| `ignoreLayout` | `true` para overlays dentro de un layout group |
| `prefab` | Ruta de un prefab anidado |

> [!WARNING]
> El spec aún no expresa gradientes, sprites, tamaño de fuente ni alineación: se reportan y se ajustan a mano después.
