# Install packages

All of them are **optional**: they change the implementation, never the architecture. Adding one to the project needs approval (`OPT-03`).

**Window > Package Manager > + > Add package from git URL**, paste the URL (each block has a **Copy** button) and click **Add**.

1. **Tools Core** first, if you'll add Fast IoC, Screen System or UI Scroller: they depend on it, and Unity doesn't install Git dependencies on its own.

```text
https://github.com/sgonzalezrozo/unity-tools-core.git
```

2. The ones you need:

**Fast IoC**: Dependency injection (needs Tools Core)

```text
https://github.com/sgonzalezrozo/unity-fast-ioc.git
```

**Screen System**: Screens, modals and layered navigation (needs Tools Core)

```text
https://github.com/sgonzalezrozo/unity-screen-system.git
```

**UI Scroller**: Recycled (virtualized) lists, grids, bento (needs Tools Core)

```text
https://github.com/sgonzalezrozo/unity-ui-scroller.git
```

**UI Foundations**: Click Controller, visual states, gradients

```text
https://github.com/sgonzalezrozo/unity-ui-foundations.git
```

**UI Tweens**: UI animation with no GC. It needs **LeoECS Core**: add it first, with this exact URL (the last MIT release), or Unity reports `Leopotam` compile errors.

```text
https://github.com/LeoECSCommunity/ecs.git#91cc7e390fa0eb4fc88a5cf111df88b1f45af37e
```

```text
https://github.com/sgonzalezrozo/unity-ui-tweens.git
```

**Enhanced Console**: Console with sections and search

```text
https://github.com/sgonzalezrozo/unity-enhanced-console.git
```

**MCP for Unity**: The agent compiles, tests and builds prefabs

```text
https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
```

> [!WARNING] Wait for each package to compile
> Add one URL, wait until Unity finishes importing and compiling, then add the next. Adding a package while Unity is still importing another can log `ScriptableSingleton already exists` and `assets located in immutable packages were unexpectedly altered`. Nothing is broken: clear the Console. If they come back when you open the project without adding a package, report it.

> [!NOTE]
> After installing one, its docs show up in this window on their own. Setup menus: Fast IoC **Tools > FastIoC > Setup**, Screen System **Tools > Screen System > Setup**.

**See also:** [Optional packages](doc:optional.capabilities) · [With or without a package](doc:optional.equivalents)
