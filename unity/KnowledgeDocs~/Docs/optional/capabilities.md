# Optional packages

Packages change the **implementation**, never the architecture. Before generating code, the agent reads `Packages/manifest.json` and notes what's there:

| Capability | Package |
|---|---|
| `fastIoC` | `com.sgonzalezrozo.fast-ioc` |
| `uiScroller` | `com.sgonzalezrozo.ui-scroller` |
| `screenSystem` | `com.sgonzalezrozo.screen-system` |
| `uiFoundations` | `com.sgonzalezrozo.ui-foundations` |
| `addressables` | `com.unity.addressables` |

| ID | Rule |
|---|---|
| `OPT-01` | Nothing uses a package that isn't installed: no code, prefab or menu |
| `OPT-02` | If it's installed, new code **uses it** |
| `OPT-03` | Adding a package needs approval |
| `OPT-04` | Don't mix both forms in one feature |
| `OPT-05` | No configuration breaks an `ARCH` rule |

> [!NOTE]
> This window does the same: each package's docs only appear when it's installed.

**See also:** [Install packages](doc:optional.install_packages) · [With or without a package](doc:optional.equivalents)
