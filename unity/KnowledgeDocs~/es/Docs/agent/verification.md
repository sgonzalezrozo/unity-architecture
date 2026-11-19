# Orden de verificación

Primero el chequeo más barato; para en el primer fallo:

```flow
Compilar + analyzers -> Tests EditMode -> Estado de generación -> Check en Play mode -> Reporte:verde
```

| Paso | Editor abierto (MCP) | Editor cerrado (`verify.sh`) |
|---|---|---|
| Compilar | `refresh_unity` y leer la Consola | `verify.sh` (exit `1` lista errores) |
| Tests | `run_tests` con filtro | `VERIFY_TEST_FILTER="..." scripts/verify.sh` |
| Generación | Leer `GenerationStatus.json` | `verify.sh` lo lee |
| Play mode | Automático (`EDIT-07`) | Paso manual |

> [!RULE] EDIT-03
> Los errores de analyzer (`UA0001`...) son errores de compilación: se arregla el código. Nunca se suprimen ni se saca el código del assembly analizado.

Cada reporte termina así:

```text
Verified: compile and analyzers (verify.sh), 14 EditMode tests passed
Not verified: Play mode check for TrophyRoom (manual)
```
