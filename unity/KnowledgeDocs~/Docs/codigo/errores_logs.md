# Errores y logs

| Situación | Qué hacer |
|---|---|
| No debería pasar (precondición rota, recurso que falta) | `throw` |
| Puede pasar (red, input inválido, sin monedas) | `Result<T>` o un estado |
| Falta un componente serializado opcional | `LogWarning` y degradar con elegancia |

- Captura excepciones **específicas**. Nunca te tragues una sin loguearla.
- Valida parámetros de API pública. No compruebes `null` en referencias inyectadas o cacheadas.

## Logs

- Prefijo con contexto: `[TrophyRoom]`, más IDs y motivos.
- `Log` para flujo, `LogWarning` para lo recuperable, `LogError` para fallos.
- Quita los logs de depuración antes de commitear.
