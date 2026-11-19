# Menus and shortcuts: Fast IoC

| Menu | For | Agent? |
|---|---|---|
| **Assets > FastIoC > New MonoInstaller** | Creates a global installer in the selected folder | No: it writes the `.cs` directly |
| **Tools > FastIoC > Setup** | First-time setup, once per project | <color=#F85149>Never</color>: opens a modal dialog |
| **Tools > FastIoC > Regenerate Code** | Regenerates the code | <color=#F85149>Never</color>: it regenerates after each compile |

> [!RULE] DI-09
> After **New MonoInstaller**: run it on `Services/`, name it `{Feature}Installer`, and add the `Client.{Feature}` namespace, the scenes and the `Priority`.

> [!TIP] Generation status
> `Assets/FastIoC/Generated/GenerationStatus.json` reports missing bindings and cycles. An installer change is done when it reports `"status": 0` with no new warnings (`EDIT-04`).
