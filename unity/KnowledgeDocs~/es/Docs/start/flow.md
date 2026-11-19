# El flujo en una línea

Todo cambio de pantalla sigue el mismo camino:

```flow
Input -> Controller -> Comando del Model -> Cambio de estado:azul
Evento sin datos:amarillo -> View lee el Model -> View pinta
```

## Dónde buscar un bug

| Síntoma | Capa culpable |
|---|---|
| Un valor incorrecto | [**Model**](doc:model.what_is_a_model) |
| Un píxel incorrecto | [**View**](doc:view.shape) |
| Un click que no hace nada | [**Controller**](doc:controller.shape) |

> [!NOTE]
> Esta separación es la recompensa de ser estrictos: siempre sabes en qué archivo está el problema.

**Ver también:** [MVC en resumen](doc:architecture.mvc_overview) · [Pull, nunca push](doc:architecture.pull_not_push)
