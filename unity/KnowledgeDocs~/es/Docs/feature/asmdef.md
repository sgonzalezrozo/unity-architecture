# Assembly definitions

```text
Assets/Client/Client.asmdef                          Todo el código cliente, Shared/ incluido
Assets/Client/{Feature}/Tests/Client.{Feature}.Tests.asmdef   Los tests EditMode de la feature
```

> [!RULE] ASM-01
> Todo el código de features compila en `Client.asmdef`. El código de una feature **no** tiene su propio `.asmdef` (sus tests sí): los analyzers, el validador de prefabs y los specs solo leen el assembly `Client`.

> [!RULE] ASM-02
> Si una feature necesita un package que **ya está** en `Packages/manifest.json`, añade su assembly a las `references` de `Client.asmdef`. Eso no necesita aprobación; añadir el package sí.

> [!RULE] ASM-03
> Los tests de una feature van en `Assets/Client/{Feature}/Tests/`, en el namespace `Client.{Feature}.Tests`, y compilan en el `Client.{Feature}.Tests.asmdef` propio de la feature, en esa carpeta. El Stop hook corre los tests de una feature por ese namespace. No hay un assembly de tests para todo el proyecto.

> [!WARNING]
> Un `.asmdef` directamente en `Assets/` captura todo el proyecto.
