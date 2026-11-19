# Building UI with MCP

With MCP for Unity the agent **builds prefabs** itself, always along the same deterministic path.

```flow
Write the spec (handoff) -> BuildFromSpec -> ValidateAsset -> Compare -> Read the hierarchy back:green
```

> [!RULE] EDIT-05
> Before building, write the **handoff** table as the spec. Afterwards, read the built hierarchy back and report any difference.

> [!RULE] EDIT-11
> Under `Assets/Client`, prefabs are built **only** with `PrefabRecipes` or a spec (`PrefabSpecs.BuildFromSpec`) called through `execute_code`. Never object by object with the generic tools (`manage_prefabs`, `manage_gameobject`). What the recipes can't build is **reported**, not improvised.

> [!RULE] EDIT-12
> After building or changing a prefab, the validator (`PrefabValidator.ValidateAsset`) and `PrefabSpecs.Compare` must both return **empty**, and both are reported.

> [!RULE] EDIT-06
> The prefab's YAML is never written as text.

> [!DONT]
> Asking the agent to open **Assets > UI Scroller > New Scroll List** or **Tools > FastIoC > Setup** through MCP. Menus with dialogs block the Editor (`EDIT-13`).
