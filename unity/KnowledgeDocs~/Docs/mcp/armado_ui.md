# Reglas de armado de UI con MCP

Con MCP for Unity el agente **construye los prefabs** él mismo, pero siempre por el mismo camino determinista.

```flow
Escribir el spec (handoff) -> BuildFromSpec -> ValidateAsset -> Compare -> Leer la jerarquía:verde
```

> [!RULE] EDIT-05
> Antes de construir, escribe la tabla de **handoff** como spec. Después lee la jerarquía construida y reporta cualquier diferencia.

> [!RULE] EDIT-11
> Bajo `Assets/Client`, los prefabs se construyen **solo** con `PrefabRecipes` o un spec (`PrefabSpecs.BuildFromSpec`) llamados desde `execute_code`. Nunca objeto a objeto con las tools genéricas (`manage_prefabs`, `manage_gameobject`). Lo que las recetas no saben hacer se **reporta**, no se improvisa.

> [!RULE] EDIT-12
> Tras construir o cambiar un prefab: el validador (`PrefabValidator.ValidateAsset`) y `PrefabSpecs.Compare` deben devolver **vacío**, y se reportan ambos.

> [!RULE] EDIT-06
> Nunca se escribe el YAML del prefab como texto.

> [!DONT]
> Pedir al agente que abra **Assets > UI Scroller > New Scroll List** o **Tools > FastIoC > Setup** por MCP. Los menús con diálogos bloquean el Editor (`EDIT-13`).
