# Menús de Fast IoC

| Menú | Para qué | ¿El agente? |
|---|---|---|
| **Assets > FastIoC > New MonoInstaller** | Crea un installer global en la carpeta seleccionada | No: escribe el `.cs` directamente |
| **Tools > FastIoC > Setup** | Configuración inicial, una vez por proyecto | <color=#F85149>Nunca</color>: abre un diálogo modal |
| **Tools > FastIoC > Regenerate Code** | Regenera el código | <color=#F85149>Nunca</color>: se regenera solo tras compilar |

> [!RULE] DI-09
> Tras **New MonoInstaller**: ejecútalo sobre `Services/`, llámalo `{Feature}Installer`, añade el namespace `Client.{Feature}`, las escenas y la `Priority`.

> [!TIP] Estado de la generación
> `Assets/FastIoC/Generated/GenerationStatus.json` dice si faltan bindings o hay ciclos. Un cambio de installer está hecho cuando reporta `"status": 0` sin warnings nuevos (`EDIT-04`).
