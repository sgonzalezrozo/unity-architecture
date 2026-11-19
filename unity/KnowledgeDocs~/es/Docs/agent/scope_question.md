# La pregunta de alcance

Un prompt corto, como "crea el feature vida del jugador para mostrarla en la UI", no dice cuánto construir. Antes de planear un feature o una pantalla nueva, el agente pregunta:

| Opción | El agente crea |
|---|---|
| **Solo código** | Los scripts. Los prefabs se describen en un handoff para ti |
| **Código y prefabs** | Los scripts y los prefabs |
| **Código y tests** | Los scripts y sus tests unitarios |
| **Código, prefabs y tests** | Todo |

> [!RULE] SCOPE-01
> El agente lo pregunta una vez, junto con el plan. Se lo salta si tu pedido ya lo dice.

> [!RULE] SCOPE-03
> El agente no escribe analyzers, herramientas de editor, generadores ni infraestructura de tests salvo que se los pidas por nombre.

> [!TIP]
> Dilo de entrada para saltarte la pregunta: "Crea el feature vida del jugador, código y prefabs, sin tests."

Sin tests, el código sigue siendo testeable y el agente lista los tests que escribiría.
