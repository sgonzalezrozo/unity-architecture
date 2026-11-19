# Rendimiento y allocations

| ID | Regla |
|---|---|
| `PERF-01` | Una feature no está en escena ni en memoria antes de necesitarse |
| `PERF-02` | Una feature libera lo que cargó al cerrarse |
| `PERF-03` | Nada corre cada frame salvo que el valor cambie cada frame. Mejor eventos |

- Reutiliza colecciones con `.Clear()` en métodos frecuentes. Devuelve colecciones vacías, no `null`.
- `StringBuilder` para construir strings en bucles.
- Pool de objetos que se crean a menudo.
- Cachea `WaitForSeconds` y similares.
- Callbacks de tweens con métodos con nombre; parámetros en campos.
- `MaterialPropertyBlock` para cambios de material por instancia.
