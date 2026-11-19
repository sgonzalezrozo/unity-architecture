# Cuándo pregunta el agente

Pregunta cuando los docs y el código no lo resuelven. Siempre antes de:

- Añadir un package o dependencia (referenciar uno que ya está en el manifest no cuenta).
- Cambiar `Shared/`, patrones base o comportamiento público.
- Usar una API sin documentar y sin precedente.
- Introducir un patrón nuevo.
- Romper cualquier regla de `AGENTS.md`.

> [!RULE] DATA-01
> Nombres, cantidades, precios y monedas salen del pedido y de lo que adjunta (spec, mockup). Si no, valores de **Estados Unidos**: inglés, dólares, formatos `en-US`.

> [!IMPORTANT]
> Nunca rellena un hueco con una suposición presentada como hecho. Si supuso algo, lo dice.
