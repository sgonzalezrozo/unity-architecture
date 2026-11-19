# Menús y atajos: UI Scroller

| Menú | Para qué |
|---|---|
| **Window > UI Scroller > Bento Layout Editor** | Dibujar un layout bento y exportarlo a JSON |
| **Assets > UI Scroller > New Scroll List** | Asistente que genera scripts y prefabs de una lista |

> [!CAUTION] LIST-09
> **New Scroll List no se usa en `Assets/Client`**: su código rompe las reglas (un `ItemController` que pinta, un `ItemModel` sin evento, datos empujados, sin namespace, un `Button`). Sirve para un prototipo **fuera** de `Assets/Client`.

Añadir el componente `Scroller` a un objeto UI vacío construye solo su `Viewport` y `Content`. El inspector muestra dirección, layout (List, Grid, Auto Grid, Bento), spacing, padding, snapping y loop.
