# UI Atom

Editor-built uGUI shapes: a `UIAtom` builds a shape with curved or angled endpoints and **bakes** it into plain `Image`s.

| Menu | For |
|---|---|
| **Tools > UI Atom > Setup** | Creates the settings asset |
| **Tools > UI Atom > Shape Generator** | Draw an endpoint and export it as a sprite + JSON |
| **Edit > Project Settings > UI Atom** | Color presets and the shape library |
| **Add Component > UI > UI Atom** | Adds the component |

- `GroupMask` clips the graphics under an atom to its shape; `IgnoreGroupMask` leaves a child out.
- With masking, add the `UIAlphaMask` shader to **Always Included Shaders**.

> [!WARNING]
> Private, work-in-progress package (`0.1.0`).
