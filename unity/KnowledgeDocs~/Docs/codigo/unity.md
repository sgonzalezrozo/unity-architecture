# Buenas prácticas de Unity

- **Nunca renombres un campo serializado** en uso sin `[FormerlySerializedAs("oldName")]`: se pierden los datos del Inspector.
- Cachea componentes en `Awake`. Nada de `GetComponent` en `Update`.
- Un GameObject no se hace `SetActive` a sí mismo: lo controla su padre.
- Evita `OnValidate` y los `[Header]` decorativos.
- Clases de datos serializables: `[Serializable]` con campos públicos (Unity no serializa auto-propiedades).
- Antes de usar sintaxis nueva, comprueba el nivel de C# de tu versión de Unity.

## Limpieza

Limpia en `OnDestroy` (o `OnDisable` para suscripciones): cancela y libera `CancellationTokenSource`, libera Addressables, para corrutinas. Las clases C# puras con suscripciones implementan `IDisposable`.
