# Prompts que funcionan

No hace falta nombrar las reglas: el agente carga `AGENTS.md` y lo que toca. Nombra un ID solo si quieres esa regla en concreto.

| Quieres | Pide |
|---|---|
| Revisar el setup | *Check that this project is set up for the .ai rules: run capability detection and editor tool detection, refresh Unity, read the Console, run the prefab validator test.* |
| Planificar | *Plan a TrophyRoom feature: a list of trophies from the backend and a details popup with a claim button. Don't write code yet.* |
| Revisar código | *Review Assets/Client/Shop for rule violations. Cite the rule ID for each one, and don't change anything.* |
| Arreglar un bug | *The coin balance doesn't update after a purchase. Fix it, with a test that fails without the fix.* |
| Explicar una regla | *Why can't a View call a Model command? Explain VIEW-02 with an example from this project.* |

## Consejos

- **Di dónde:** una ruta como `Assets/Client/Rewards/ClaimTrophyBanner/` fija feature, carpeta y namespace.
- **Di qué guarda el Model:** "el Model cuenta los claims" dice dónde vive el estado y qué testear.
- **Adjunta el look:** la ruta de un PNG (mockup o captura) fija colores, orden y espaciado.
- **Pide un spec** si vas a iterar un prefab.
- **Reglas solo de este proyecto** van en tu `AGENTS.md` raíz, nunca dentro de `.ai`.
