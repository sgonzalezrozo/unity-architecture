# El flujo en una línea

Todo cambio de pantalla sigue el mismo camino:

```flow
Input -> Controller -> Comando del Model -> Cambio de estado:azul
Evento sin datos:amarillo -> View lee el Model -> View pinta
```

## Dónde buscar un bug

| Síntoma | Capa culpable |
|---|---|
| Un valor incorrecto | [**Model**](doc:model.que_es) |
| Un píxel incorrecto | [**View**](doc:view.forma) |
| Un click que no hace nada | [**Controller**](doc:controller.forma) |

> [!NOTE]
> Esta separación es la recompensa de ser estrictos: siempre sabes en qué archivo está el problema.

**Ver también:** [MVC en resumen](doc:arquitectura.mvc_resumen) · [Pull, nunca push](doc:arquitectura.pull_no_push)
