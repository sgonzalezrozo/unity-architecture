# Input y raycast en prefabs

| ID | Regla |
|---|---|
| `PREFAB-06` | Nada de listeners `UnityEvent` persistentes ni `EventTrigger`: todo input pasa por un Controller |
| `PREFAB-09` | `Action` lleva una `Image` con **alpha 0** y **Cull Transparent Mesh** activado: no dibuja ni causa overdraw |
| `PREFAB-14` | El `Background` de un elemento con `Action` tiene raycast **on**. También el de una pantalla, pero no el de cada layer |
| `PREFAB-15` | Toda referencia serializada está **asignada** en el prefab |
| `PREFAB-16` | Dentro de un layout group, `Background`, `Action` y overlays llevan `LayoutElement` con **Ignore Layout** |

<!-- if: com.sgonzalezrozo.ui-foundations -->
> [!TIP]
> Con UI Foundations, el Controller (`BaseClickController`) **es** el gráfico: el `Action` no necesita `Image`.
<!-- endif -->
