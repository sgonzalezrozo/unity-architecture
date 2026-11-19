# Reglas visuales de prefabs

| ID | Regla |
|---|---|
| `PREFAB-02` | Lo que llena su contenedor usa anchors **stretch** (0,0 a 1,1). Lo de tamaño fijo, un anchor de punto. Nada de anchors fraccionarios (0.2 a 0.8) |
| `PREFAB-03` | Con contenido dinámico, el **pivot** apunta hacia donde crece: Y `1` si crece hacia abajo |
| `PREFAB-04` | Texto siempre `TextMeshProUGUI`, nunca `UnityEngine.UI.Text`. Sprites y fuentes fijos se ponen en el prefab, no en un campo de la View |
| `PREFAB-05` | Nada de `Animator` ni `Animation` en UI: el movimiento es un **tween** que lanza una View |
| `PREFAB-07` | Recortes rectangulares con `RectMask2D`, no `Mask` |
| `PREFAB-08` | Un contenedor que se llena en runtime está **vacío** en el prefab |
| `PREFAB-12` | Lo que anima o cambia a menudo tiene su propio `Canvas` anidado |
| `PREFAB-13` | Máximo unos **5 niveles** bajo la raíz |
