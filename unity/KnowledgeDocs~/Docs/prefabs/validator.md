# Validate prefabs

> [!RULE] TEST-12
> Every prefab under `Assets/Client` passes the **prefab validator**. Fix the prefab, never the validator.

> [!TIP] Shortcut
> **Tools > Unity Architecture > Validate Client Prefabs**

| Checks | Rules |
|---|---|
| <color=#F85149>Errors</color> | `PREFAB-01, 04, 05, 06, 09, 14, 15, 16, 17`, `ARCH-05`, `INPUT-01..03`, `SCOPE-02`, `SCOPE-04`, `VIEW-03` |
| <color=#D29922>Warnings</color> | `PREFAB-07` (`Mask`) and `PREFAB-13` (depth) |
| Not checked | `PREFAB-02, 03, 08, 10, 11, 12`: they need intent the prefab doesn't record |

It also runs as an EditMode test (`ClientPrefabsTests`) and in batch mode with `-executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine`.
