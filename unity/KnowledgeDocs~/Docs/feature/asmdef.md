# Assembly definitions

```text
Assets/Client/Client.asmdef                          All client code, Shared/ included
Assets/Client/{Feature}/Tests/Client.{Feature}.Tests.asmdef   The feature's EditMode tests
```

> [!RULE] ASM-01
> All feature code compiles in `Client.asmdef`. A feature's code **doesn't** get its own `.asmdef` (its tests do): the analyzers, the prefab validator and the specs only read the assembly named `Client`.

> [!RULE] ASM-02
> When code uses a package that's **already** in `Packages/manifest.json`, `Client.asmdef` (and the feature's `Client.{Feature}.Tests.asmdef` when its tests use it) lists every assembly that package needs, in the same change that adds the first `using`. Unity doesn't add them. That needs no approval; adding the package does.

| Package | Add to **Assembly Definition References** |
|---|---|
| Always | `UnityEngine.UI`, `Unity.TextMeshPro` |
<!-- if: com.sgonzalezrozo.fast-ioc -->
| Fast IoC | `FastIoC`, `FastIoC.Core`, `ToolsCore` |
<!-- endif -->
<!-- if: com.sgonzalezrozo.ui-scroller -->
| UI Scroller | `UIScroller`, `ToolsCore` (`ISlot<T>` derives from a Tools Core interface) |
<!-- endif -->
<!-- if: com.sgonzalezrozo.screen-system -->
| Screen System | `ScreenSystem`, `ToolsCore` |
<!-- endif -->
<!-- if: com.sgonzalezrozo.ui-foundations -->
| UI Foundations | `UIFoundations` |
<!-- endif -->
<!-- if: com.sgonzalezrozo.ui-tweens -->
| UI Tweens | `UITweens` |
<!-- endif -->
<!-- if: com.unity.addressables -->
| Addressables | `Unity.Addressables`, `Unity.ResourceManager` |
<!-- endif -->

Each package lists its own in the **Assembly references** section of its `Documentation~/agent-rules.md`.

> [!WARNING] CS0246
> `The type or namespace name 'UIScroller' could not be found` means a missing reference: add it to `Client.asmdef`. Never move the code out of `Client` to make it compile (`ASM-01`).

> [!RULE] ASM-03
> A feature's tests go in `Assets/Client/{Feature}/Tests/`, in the namespace `Client.{Feature}.Tests`, and compile in the feature's own `Client.{Feature}.Tests.asmdef` in that folder. The Stop hook runs one feature's tests by that namespace. There's no project-wide test assembly.

> [!WARNING]
> An `.asmdef` directly in `Assets/` captures the whole project.
