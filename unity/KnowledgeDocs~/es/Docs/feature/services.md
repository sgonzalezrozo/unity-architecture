# La carpeta Services

| Archivo | Rol |
|---|---|
| `{Feature}Module.cs` | Model C# puro que envuelve el backend de la feature |
| `I{Feature}Connector.cs`, `{Feature}Connector.cs` | Interfaz e implementación de las llamadas |
| `{Feature}Data.cs` | Clases de datos del backend |
<!-- if: com.sgonzalezrozo.fast-ioc -->
| `{Feature}Installer.cs` | Bindings de Fast IoC |
<!-- endif -->
<!-- if: com.sgonzalezrozo.screen-system -->
| `ScreenDefinition` (`.asset`) | Una por pantalla, de Screen System |
<!-- endif -->

> [!RULE] FEAT-01
> Una feature no referencia Views, Controllers ni internos de scope de otra feature. Sí puede leer un Model compartido o inyectado.

<!-- if: com.sgonzalezrozo.screen-system -->
> [!NOTE]
> Una pantalla que otras features abren deja su `ScreenDefinition` en la feature donde se creó. Nunca se mueve a `Shared/` ni se copia.
<!-- endif -->

**Ver también:** [Las piezas del backend](doc:backend.pieces) · [Carpetas](doc:feature.folders)
