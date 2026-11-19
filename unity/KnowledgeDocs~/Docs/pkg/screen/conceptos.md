# Screen System: conceptos

Un gestor de UI por **capas** para uGUI y UI Toolkit. Toda la UI vive en un objeto persistente `ScreenSystem`.

- Una **pantalla** = un prefab + una lista ordenada de **layers** (`LayerDefinition`), como capas de un editor de imagen.
- Una barra superior o un fondo es **un** layer que cualquier pantalla lista; las pantallas comparten la instancia.
- Como mucho se pinta **un fullscreen, un modal y un alert**. Detrás de un modal hay una captura con blur.
- Las pantallas se cargan al pedirlas y se descargan al cambiar de escena.

| Tipo | Uso |
|---|---|
| `Fullscreen` | Pantalla normal |
| `Modal` | Popup o confirmación; uno abierto a la vez |
| `Alert` | Mensaje bloqueante (conexión perdida); se cierra con `DismissAlert()` |

> [!RULE] SCR-04
> Una parte repetida en varias pantallas es **un layer** listado en cada `LayerDefinition`, no una copia.
