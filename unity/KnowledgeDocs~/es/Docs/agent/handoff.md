# Handoff de un prefab

Sin MCP, el agente no puede construir un prefab: lo hace una persona con sus instrucciones (o desde un spec con **Build Prefab From Spec**). Con MCP, la tabla es el spec contra el que se comprueba. En ambos casos **no deja nada a adivinar**.

| ID | Incluye |
|---|---|
| `HAND-01` | Cada objeto con padre, anchors, pivot, tamaño, posición, escala y componentes; qué contenedores se llenan en runtime |
| `HAND-02` | Raycast Target de cada `Graphic` (solo `Action` y `Background` que bloquea, on) |
| `HAND-03` | Cada campo serializado y qué asignarle |
| `HAND-04` | Setup del primer uso (TMP Essentials, módulo de input del EventSystem) |
| `HAND-05` | Qué probar en Play mode (reportado como no verificado) |

```text
| Object | Parent | Anchors | Pivot | Size, position | Scale | Components | Raycast | Runtime |
|---|---|---|---|---|---|---|---|---|
| CoinBalance | Canvas | stretch | 0.5, 0.5 | fills parent | 1 | CoinBalanceModel, CoinBalanceView | n/a | no |
| BalanceText | CoinBalance | top center | 0.5, 1 | 400x100, y -120 | 1 | TextMeshProUGUI | off | no |
```
