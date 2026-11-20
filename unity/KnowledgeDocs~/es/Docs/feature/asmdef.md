# Assembly definitions

```text
Assets/Client/Client.asmdef                          Todo el código cliente, Shared/ incluido
Assets/Client/Tests/Client.Tests.asmdef              Todos los tests EditMode
Assets/Client/{Feature}/Tests/Client.Tests.asmref    Añade los tests de la feature a Client.Tests
```

> [!RULE] ASM-01
> Todo el código de features compila en `Client.asmdef`. Una feature **no** tiene su propio `.asmdef`: los analyzers, el validador de prefabs y los specs solo leen el assembly `Client`.

> [!RULE] ASM-02
> Si una feature necesita un package que **ya está** en `Packages/manifest.json`, añade su assembly a las `references` de `Client.asmdef`. Eso no necesita aprobación; añadir el package sí.

> [!RULE] ASM-03
> Los tests de una feature van en `Assets/Client/{Feature}/Tests/`, con un `Client.Tests.asmref`, en el namespace `Client.{Feature}.Tests`. El Stop hook corre los tests de una feature por ese namespace. Una feature **no** tiene su propio `.asmdef` de tests.

> [!WARNING]
> Un `.asmdef` directamente en `Assets/` captura todo el proyecto.
