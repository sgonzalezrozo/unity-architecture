# Las piezas del backend

```flow
Backend:teal -> Connector:teal -> Module -> Evento:amarillo -> View lee el Module
Controller -> Comando del Module
```

| Pieza | Tipo | Trabajo |
|---|---|---|
| `{Feature}Data` | Clase de datos | La respuesta del backend tal cual |
| `I{Feature}Connector` | Interfaz | Las llamadas posibles; permite falsear el backend en tests |
| `{Feature}Connector` | Implementación | Hace las llamadas, devuelve datos, **sin estado** |
| `{Feature}Module` | Model C# puro | Envuelve el Connector y guarda los datos de la feature |

## Qué va dónde

| Estado | Vive en |
|---|---|
| Datos del backend, estado de carga, selección compartida | **Module** (uno por feature) |
| Estado de una sola pantalla (orden, edición en curso) | El Model de esa pantalla |

**Ver también:** [Reglas de datos](doc:backend.reglas) · [Async y red](doc:backend.async_y_red) · [Ejemplo Trophy Room](doc:ejemplos.trophy_room)
