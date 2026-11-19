# Fast IoC: qué es

Inyección de dependencias con **código generado** y sin reflexión en runtime. Los bindings que faltan y los ciclos se detectan **antes de darle a Play**.

- **Installers por feature:** un installer junto al código de la feature, sin lista central.
- **Errores antes de Play:** ciclos, bindings que faltan y assets inválidos fallan la generación.
- **Sin reflexión:** registros e inyectores se generan al editar; las escenas se inyectan desde un manifest horneado.
- Singletons, scope de escena, transient, assets, `Lazy<T>`, `Func<T>`, instanciado de prefabs con datos e inicialización async.

> [!NOTE]
> Añade el define `FAST_IoC` a todos los targets al cargarse: commitea ese cambio de Player Settings.

## Cómo se usa aquí

| Clase | Recibe dependencias por |
|---|---|
| MonoBehaviour | Campo `internal` sin atributo |
| Clase C# pura | Su constructor público |
