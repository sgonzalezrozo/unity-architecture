# Install packages

All of them are **optional**: they change the implementation, never the architecture. Adding one to the project needs approval (`OPT-03`).

**Window > Package Manager > + > Add package from git URL**, in this order:

1. **Tools Core** first: the others depend on it, and Unity doesn't install Git dependencies on its own.

```text
https://github.com/sgonzalezrozo/unity-tools-core.git
```

2. The ones you need:

| Package | For | URL |
|---|---|---|
| Fast IoC | Dependency injection | `https://github.com/sgonzalezrozo/unity-fast-ioc.git` |
| Screen System | Screens, modals and layered navigation | `https://github.com/sgonzalezrozo/unity-screen-system.git` |
| UI Scroller | Recycled (virtualized) lists, grids, bento | `https://github.com/sgonzalezrozo/unity-ui-scroller.git` |
| UI Foundations | Click Controller, visual states, gradients | `https://github.com/sgonzalezrozo/unity-ui-foundations.git` |
| UI Tweens | UI animation with no GC | `https://github.com/sgonzalezrozo/unity-ui-tweens.git` |
| Enhanced Console | Console with sections and search | `https://github.com/sgonzalezrozo/unity-enhanced-console.git` |
| MCP for Unity | The agent compiles, tests and builds prefabs | `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity` |

> [!NOTE]
> After installing one, its docs show up in this window on their own. Setup menus: Fast IoC **Tools > FastIoC > Setup**, Screen System **Tools > Screen System > Setup**.

**See also:** [Optional packages](doc:optional.capabilities) · [With or without a package](doc:optional.equivalents)
