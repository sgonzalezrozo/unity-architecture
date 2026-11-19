# Reglas al tocar Unity

> [!RULE] EDIT-06
> Nunca se escribe YAML de `.prefab`, `.unity`, `.asset` o `.meta` como texto. El serializer de Unity es su dueño.

- Un archivo movido se mueve con su `.meta`.
- No se cambia código generado ni packages externos.
- Nunca se renombra un campo serializado sin `[FormerlySerializedAs]`.
- Se queda en el alcance acordado: menciona otros problemas, pero no los arregla sin pedirlo.

> [!RULE] API
> El agente **no inventa APIs**. Fuera de lo documentado, lee el código del package o pregunta.
