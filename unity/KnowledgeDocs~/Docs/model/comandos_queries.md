# Comandos y queries

> [!RULE] MODEL-02
> Un método es **query** (solo lee) o **comando** (cambia estado), nunca las dos cosas. `Try*` es la excepción aceptada.

> [!RULE] MODEL-03
> Un comando **valida su input**. Lo que el jugador puede provocar (pocas monedas) se ignora o devuelve un estado. Lo que solo un bug provoca (un ID desconocido) lanza excepción. Las reglas de negocio **nunca** van en un Controller.

| Situación | Qué hace el comando |
|---|---|
| No hay monedas suficientes | Ignora o devuelve un estado |
| ID que no existe | `throw` |
| Ya está en ese estado | `return` sin evento |

> [!RULE] MODEL-11
> El Model termina de cambiar su estado **antes** de lanzar el evento. Quien escucha no llama comandos sobre el Model que lo lanzó.
