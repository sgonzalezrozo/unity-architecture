# Ejemplo: pedir un prefab con el Editor abierto

```text
Build a ClaimTrophyBanner for a new Rewards feature in Assets/Client/Rewards/ClaimTrophyBanner/:
a background, a title text, a trophy icon, and a tap that claims the trophy. The Model counts
claims, and the banner shows "Claimed" after the first tap. Write the handoff as a JSON spec,
build it with PrefabSpecs.BuildFromSpec, validate and compare it, run the related tests, and do
the Play mode check.
```

Lo que hace el agente, en orden:

1. Escribe Model, View y Controller en la carpeta, y los tests del Model en `Assets/Tests/Rewards/`.
1. Compila (`refresh_unity`) y corre los tests nuevos.
1. Escribe `ClaimTrophyBanner.json`: `UI Content` con fondo, título e icono, y el `Action` al lado.
1. Lo construye con `execute_code` (`BuildFromSpec`, `ValidateAsset`, `Compare`).
1. Reporta validador y diferencias (ambos vacíos) y relee la jerarquía.
1. Corre `ClientPrefabsTests`.
1. Entra en Play mode, toca el `Action`, comprueba Model y View, lee la Consola y sale.
