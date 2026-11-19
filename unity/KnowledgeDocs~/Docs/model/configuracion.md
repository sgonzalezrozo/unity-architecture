# Configuración de un Model

> [!RULE] MODEL-09
> Un Model **no tiene campos serializados** (`UA0013`).

> [!RULE] MODEL-10
> Un valor que se ajusta fuera del código viene de un **asset de configuración** inyectado (`ScriptableObject`) o del JSON del backend. Todo lo demás es una constante.

| Valor | Dónde va |
|---|---|
| Máximo de vidas fijo | `private const int MAX_LIVES = 3;` |
| Precios que ajusta diseño | `ScriptableObject` inyectado |
| Precios que vienen del servidor | JSON del backend |

> [!NOTE]
> Sin contenedor, el asset se carga por dirección o ruta (Addressables o `Resources`).
