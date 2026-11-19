# Haz lo mínimo

> [!RULE] ARCH-10
> Nada de interfaces o abstracciones sin un **segundo uso** o una necesidad de test.

> [!RULE] ARCH-11
> Haz lo mínimo que termina la necesidad por completo. Una feature que no se usa **no cuesta nada** en runtime.

- Una escena vacía debe ir mucho más rápida que una con todas las features listas.
- Carga cada feature cuando se abre y libérala al cerrarla (`PERF-01`, `PERF-02`).

> [!DONT]
> `IInventoryService` con una sola implementación "por si acaso".
