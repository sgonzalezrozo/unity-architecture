# Assembly definitions

```text
Assets/Client/Client.asmdef        Todo el código cliente, Shared/ incluido
```

> [!RULE] ASM-01
> Todo el código de features compila en `Client.asmdef`. Una feature **no** tiene su propio `.asmdef`: los analyzers, el validador de prefabs y los specs solo leen el assembly `Client`.

> [!RULE] ASM-02
> Si una feature necesita un package que **ya está** en `Packages/manifest.json`, añade su assembly a las `references` de `Client.asmdef`. Eso no necesita aprobación; añadir el package sí.

> [!WARNING]
> Un `.asmdef` directamente en `Assets/` captura todo el proyecto.
