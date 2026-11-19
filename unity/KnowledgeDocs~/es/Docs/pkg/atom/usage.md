# UI Atom

Formas uGUI construidas en el editor: un `UIAtom` crea una forma con extremos curvos o en ángulo y la **hornea** en `Image`s normales.

| Menú | Para qué |
|---|---|
| **Tools > UI Atom > Setup** | Crea el asset de configuración |
| **Tools > UI Atom > Shape Generator** | Dibuja un extremo y lo exporta como sprite + JSON |
| **Edit > Project Settings > UI Atom** | Presets de color y librería de formas |
| **Add Component > UI > UI Atom** | Añade el componente |

- `GroupMask` recorta los gráficos bajo un atom con su forma; `IgnoreGroupMask` excluye un hijo.
- Con máscaras, añade el shader `UIAlphaMask` a **Always Included Shaders**.

> [!WARNING]
> Package privado y en desarrollo (`0.1.0`).
