# Validar prefabs

> [!RULE] TEST-12
> Todo prefab bajo `Assets/Client` pasa el **validador de prefabs**. Se arregla el prefab, nunca el validador.

> [!TIP] Atajo
> **Tools > Unity Architecture > Validate Client Prefabs**

| Qué revisa | Reglas |
|---|---|
| <color=#F85149>Errores</color> | `PREFAB-01, 04, 05, 06, 09, 14, 15, 16, 17`, `ARCH-05`, `INPUT-01..03`, `SCOPE-02`, `SCOPE-04`, `VIEW-03` |
| <color=#D29922>Avisos</color> | `PREFAB-07` (`Mask`) y `PREFAB-13` (profundidad) |
| No revisa | `PREFAB-02, 03, 08, 10, 11, 12`: necesitan intención que el prefab no guarda |

También corre como test EditMode (`ClientPrefabsTests`) y en batch con `-executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine`.
