# Packages opcionales

Los packages cambian la **implementación**, nunca la arquitectura. Antes de generar código, el agente lee `Packages/manifest.json` y marca qué hay:

| Capacidad | Package |
|---|---|
| `fastIoC` | `com.sgonzalezrozo.fast-ioc` |
| `uiScroller` | `com.sgonzalezrozo.ui-scroller` |
| `screenSystem` | `com.sgonzalezrozo.screen-system` |
| `uiFoundations` | `com.sgonzalezrozo.ui-foundations` |
| `addressables` | `com.unity.addressables` |

| ID | Regla |
|---|---|
| `OPT-01` | Nada usa un package que no está: ni código, ni prefab, ni menú |
| `OPT-02` | Si está instalado, el código nuevo **lo usa** |
| `OPT-03` | Añadir un package necesita aprobación |
| `OPT-04` | No mezcles las dos formas en una feature |
| `OPT-05` | Ninguna configuración rompe una regla `ARCH` |

> [!NOTE]
> Esta ventana hace lo mismo: las secciones de cada package solo aparecen si está instalado.
