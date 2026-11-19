# Assembly definitions

```text
Assets/Client/Client.asmdef        All client code, Shared/ included
```

> [!RULE] ASM-01
> All feature code compiles in `Client.asmdef`. A feature **doesn't** get its own `.asmdef`: the analyzers, the prefab validator and the specs only read the assembly named `Client`.

> [!RULE] ASM-02
> When a feature needs a package that's **already** in `Packages/manifest.json`, add its assembly to the `references` of `Client.asmdef`. That needs no approval; adding the package does.

> [!WARNING]
> An `.asmdef` directly in `Assets/` captures the whole project.
