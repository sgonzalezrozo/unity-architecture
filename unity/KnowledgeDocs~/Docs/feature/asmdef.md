# Assembly definitions

```text
Assets/Client/Client.asmdef                          All client code, Shared/ included
Assets/Client/Tests/Client.Tests.asmdef              All EditMode tests
Assets/Client/{Feature}/Tests/Client.Tests.asmref    Adds the feature's tests to Client.Tests
```

> [!RULE] ASM-01
> All feature code compiles in `Client.asmdef`. A feature **doesn't** get its own `.asmdef`: the analyzers, the prefab validator and the specs only read the assembly named `Client`.

> [!RULE] ASM-02
> When a feature needs a package that's **already** in `Packages/manifest.json`, add its assembly to the `references` of `Client.asmdef`. That needs no approval; adding the package does.

> [!RULE] ASM-03
> A feature's tests go in `Assets/Client/{Feature}/Tests/`, with a `Client.Tests.asmref`, in the namespace `Client.{Feature}.Tests`. The Stop hook runs one feature's tests by that namespace. A feature **doesn't** get its own test `.asmdef`.

> [!WARNING]
> An `.asmdef` directly in `Assets/` captures the whole project.
