# Modales y navegación

- Los popups son prefabs aparte, en la carpeta de la pantalla que los usa. Su estado vive en un Model.
- Pasa **de qué trata** la navegación (qué trofeo mostrar) como parámetro al abrir.
- El estado que comparten varias pantallas se queda en un **Model**: la pantalla A lo pone, la B lo lee.

> [!RULE] Escenas
> Los cambios de escena pasan por **un único scene loader** del proyecto. Nunca `SceneManager` desde código de feature.

> [!NOTE]
> Mostrar un menú no es lo mismo que salir de una escena de gameplay.
