# Menús y atajos: UI Scroller

| Menú | Para qué |
|---|---|
| **Window > UI Scroller > Bento Layout Editor** | Dibujar un layout bento y exportarlo a JSON |
| **Assets > UI Scroller > New Scroll List** | Asistente que genera scripts y prefabs de una lista |

> [!NOTE] LIST-09
> **New Scroll List** escribe la lista separada como piden las reglas: `{Name}ItemData`, `{Name}ItemSlotModel` (el `ISlot`), `{Name}ItemSlotView`, `{Name}Scroller`, `{Name}ListModel` (dueño de los items, `IItemSource`) y `{Name}ListView`, en el namespace de la feature, y añade sus assemblies al `.asmdef` de la carpeta. Los items expandibles se abren con `Toggle{Name}ItemController` en un `Action`. Pasa los analyzers, y sus prefabs siguen las reglas de prefabs (`Action`, `UI Content`, raycasts).

> [!WARNING]
> Un UI Scroller antiguo cuyo asistente escribe `{Name}ItemController`, `{Name}ScrollList` y `{Name}Instantiator` rompe las reglas: no lo uses en `Assets/Client`. El agente nunca ejecuta el asistente (`EDIT-13`): escribe los mismos archivos él mismo.

Añadir el componente `Scroller` a un objeto UI vacío construye solo su `Viewport` y `Content`. El inspector muestra dirección, layout (List, Grid, Auto Grid, Bento), spacing, padding, snapping y loop.
