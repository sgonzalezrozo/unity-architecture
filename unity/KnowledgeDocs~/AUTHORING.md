# Cómo escribir estas guías

Guía interna para mantener los docs del Rules Guide. **No aparece en la ventana**: los docs son fijos y se mantienen junto con las reglas de `.ai`, no por proyecto.

> [!TIP]
> Cada entrada de `knowledge.json` lleva `source` (la regla original) y, si es de un package, `requires` con su nombre: solo se muestra si está instalado. `requiresMissing` hace lo contrario.

## Dónde vive todo

| Archivo | Para qué |
|---|---|
| `KnowledgeDocs~/knowledge.json` | El índice: título, resumen, categoría, color y palabras clave |
| `KnowledgeDocs~/Docs/*.md` | Un documento por tema |
| `KnowledgeDocs~/Images/` | Capturas y diagramas (`.png` o `.jpg`) |

La `~` del nombre hace que Unity **no importe** la carpeta: no crea `.meta` ni assets, pero la ventana la lee del disco.

## Texto

- **Negrita** con `**texto**`, *cursiva* con `*texto*`, ~~tachado~~ con `~~texto~~`.
- ==Resaltado== con `==texto==`.
- Código en línea con comillas invertidas: `GetComponentInParent<TModel>()`.
- Color libre con la etiqueta de Unity `<color=#hex>texto</color>`: <color=#3FB950>verde</color>, <color=#F85149>rojo</color>.
- Los [enlaces](https://example.com) se muestran en color, pero no se pueden pulsar.

## Callouts de color

Empieza una cita con `> [!TIPO]` y, si quieres, un título propio.

> [!NOTE]
> Información útil que conviene saber.

> [!TIP] Truco
> Una forma más rápida de hacerlo.

> [!IMPORTANT]
> Algo que no puedes pasar por alto.

> [!WARNING]
> Puede romper algo si no tienes cuidado.

> [!CAUTION]
> Peligro: consecuencias graves.

> [!DO]
> Lo correcto. Úsalo junto a un `[!DONT]` para comparar.

> [!DONT]
> Lo incorrecto.

> [!RULE] ARCH-01
> Una regla con su ID, para enlazarla con `AGENTS.md`.

> [!EXAMPLE]
> Un ejemplo concreto.

También funcionan en español: `[!NOTA]`, `[!CONSEJO]`, `[!CUIDADO]`, `[!PELIGRO]`, `[!HACER]`, `[!EVITAR]`, `[!REGLA]`, `[!EJEMPLO]`.

## Listas

1. Las listas numeradas se renumeran solas.
1. Puedes escribir `1.` en todas las líneas.
   - Y anidar con dos o tres espacios.
     - Hasta varios niveles.

- [x] Checklist hecha
- [ ] Checklist pendiente

## Código

Indica el lenguaje después de las comillas para tener colores. Cada bloque tiene botón **Copiar**.

```csharp
public class LivesModel : MonoBehaviour
{
    public event Action OnLivesChanged;

    private int remainingLives = 3; // estado inicial en el inicializador
}
```

## Diagramas de flujo

Un bloque de código con lenguaje `flow` dibuja cajas con flechas. Separa los pasos con `->`. Las capas MVC se colorean solas; fuerza un color con `:verde`, `:rojo`, `:#FF00FF`...

```flow
Input -> Controller -> Model -> View
Botón:gris -> Backend:teal -> Resultado:verde
```

Cada línea es una fila. Si no cabe, salta de línea sola.

## Imágenes

```text
![Pie de foto](../Images/mi_captura.png "Título opcional")
```

La ruta es relativa al `.md`. Si el nombre termina en `@2x` se dibuja a la mitad (capturas retina). Si la imagen no existe, verás un recuadro así:

![Ejemplo de imagen que falta](../Images/ejemplo_que_no_existe.png)

> [!NOTE]
> La fuente del editor no tiene emojis: usa callouts y colores en lugar de iconos.

## Contenido que depende de un tool

- **Doc entero:** `"requires": ["com.x.package"]` en `knowledge.json` (o `requiresMissing` para lo contrario).
- **Parte de un doc:** bloques condicionales, cada marcador en su propia línea:

```text
<!-- if: com.sgonzalezrozo.screen-system -->
Texto con Screen System
<!-- else -->
Texto sin Screen System
<!-- endif -->
```

También `<!-- if-not: ... -->`. Se pueden anidar.

## Portada

`homeSections` en `knowledge.json` define las secciones; una entrada aparece en la portada con `"home": "<sección>"` y `"homeOrder"`.

## Enlaces

- A otro doc: `[Model](doc:model.que_es)` (el `id` de `knowledge.json`).
- Los IDs de regla en código (`` `VIEW-03` ``, `` `UA0012` ``) enlazan solos al doc que tiene ese ID en sus keywords (prefiere el que lo nombra en el resumen).
- Una URL `https://...` se abre en el navegador.
