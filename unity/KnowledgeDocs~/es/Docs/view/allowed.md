# Qué puede y qué no puede una View

| <color=#3FB950>Puede</color> | <color=#F85149>No puede</color> |
|---|---|
| Leer queries de Models | Llamar un comando, síncrono o async (`VIEW-02`) |
| Cambiar activo, color, tamaño, texto, alpha y sprites (`VIEW-05`) | Implementar `IPointer*` u otro input (`VIEW-04`, `UA0002`) |
| Formatear valores para mostrarlos | Conocer servicios o Connectors (`ARCH-01`) |
| Iniciar un tween al reaccionar a un evento | Usar `Animator` o `Animation` en UI (`PREFAB-05`) |

> [!DONT]
> Una View que llama `module.LoadAsync()`.

> [!DO]
> Un Controller llama al comando, y la View lee el resultado.
