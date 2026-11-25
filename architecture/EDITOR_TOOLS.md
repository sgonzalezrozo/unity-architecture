# Editor tools

**Load when:** verifying a change, or when the agent can reach the Unity Editor through MCP, the Unity CLI or a verify script.

An agent that can compile, test and inspect the project checks its own work. One that can't must say so. This document decides which tool does the checking. It never changes the [architecture](../AGENTS.md#architecture-invariants).

## Editor capabilities

These capabilities come from the [profile](OPTIONAL_PACKAGES.md#the-profile) with the package ones (`OPT-06`). A step that needs one of these tools runs only when its capability is `true`; otherwise it's left out and reported as not verified (`OPT-01`, `EDIT-01`).

| Capability | `true` when |
|---|---|
| `editorBridge` | The agent has tools that drive a running Unity Editor: the Unity CLI (`unity` command, or its `unity mcp` mode, with `com.unity.pipeline` in the manifest), [MCP for Unity](https://github.com/CoplayDev/unity-mcp) (`com.coplaydev.unity-mcp`) or another Unity MCP server |
| `verifyScript` | `scripts/verify.sh` exists. It compiles and runs the EditMode tests in batch mode, with the Editor closed |
| `generationStatus` | `fastIoC` is `true`. `Assets/FastIoC/Generated/GenerationStatus.json` reports missing bindings and cycles |
| `prefabTools` | `com.sgonzalezrozo.unity-architecture-enforcement` is in `Packages/manifest.json` (the enforcement package's install adds it from `.ai-enforcement/unity`): `PrefabRecipes`, `PrefabSpecs` and `PrefabValidator`, described in [Prefabs](PREFABS.md#building-a-prefab) |

Unity's in-Editor MCP server in the AI Assistant package (`com.unity.ai.assistant`) is deprecated by Unity. Treat it as an `editorBridge`, but don't suggest it: the Unity CLI replaces it.

A bridge and the verify script can't both own the project. `verify.sh` needs the Editor closed, and a bridge needs it open. While the Editor is open, the Editor itself writes its compile and test results to `Logs/verify/` (from the reporters in the enforcement package, `.ai-enforcement/unity`), and `scripts/verify-editor.sh` reads them.

### With MCP for Unity

| Need | Tool | Note |
|---|---|---|
| Compile, read errors | `refresh_unity`, `read_console` | Core tools, on by default |
| Run tests | `run_tests`, `get_test_job` | **Testing** tool group, off by default |
| Build and check prefabs | `execute_code` | **Scripting Extensions** tool group, off by default |
| Play mode | `manage_editor` (`play`, `stop`) | Core tools |

If a tool the task needs isn't available, report which group to turn on in **Window > MCP for Unity > Tools**; don't fall back to the generic tools for prefabs (`EDIT-11`). Without Roslyn installed in that window, `execute_code` compiles C# 6: write `UnityEngine.Object`, not `Object`, and no newer syntax. The setup is in the [installation guide](../docs/INSTALLATION.md#6-optional-set-up-mcp-for-unity).

## Rules

| ID | Rule |
|---|---|
| `EDIT-01` | A claim that code compiles, passes tests or runs MUST come from a tool in this document (`DET-02`). Without one, report it as not verified. |
| `EDIT-02` | After a script change, the agent MUST wait for the compile to finish, then read every error and warning it caused before it reports. With `editorBridge`, read the Console. Otherwise, run `verify.sh`. |
| `EDIT-03` | Analyzer diagnostics (`UA0001` and up) are compile errors. Fix the code. MUST NOT suppress, disable or move code out of the analyzed assembly to pass. |
| `EDIT-04` | With `generationStatus`, a change to an installer, constructor or injected field is done only when `GenerationStatus.json` reports `"status": 0` with no new `warnings`. Fix installers or code, never the generated files. |
| `EDIT-05` | With `editorBridge`, the agent MAY create GameObjects, components and prefabs through the bridge's editor tools (with `prefabTools`, as `EDIT-11` says). It MUST still write the [prefab handoff](workflow/prefab-handoff.md#prefab-handoff) table first, as the spec, then read the built hierarchy back and report any difference. |
| `EDIT-06` | MUST NOT write `.prefab`, `.unity`, `.asset` or `.meta` YAML as text, through a bridge or not. Unity's serializer owns those files. |
| `EDIT-07` | With `editorBridge`, a new screen's Play mode check (`TEST-10`) is automated: enter Play mode, open the screen, read the Console, exit. Report it as verified only if all of that ran. |
| `EDIT-08` | Bridge actions that add or remove packages, change Project Settings, delete assets or start a build MUST follow [When to ask](workflow/planning.md#when-to-ask). |
| `EDIT-09` | Prefer a package's own validation tool or status file to the agent's judgment of that package (`DET-01`). |
| `EDIT-10` | With the Editor open, after changing scripts the agent MUST ask the Editor to compile (`refresh_unity` with MCP for Unity) before it finishes: an Editor without focus doesn't refresh on its own. It runs the tests related to the change (`TEST-11`) in the Editor, with `run_tests` filtered by `test_names`, `group_names` or `assembly_names`, then `get_test_job` until it finishes. It runs every EditMode test only when someone asks for the full suite. |
| `EDIT-11` | With `editorBridge` and `prefabTools`, the agent MUST build or change a prefab under `Assets/Client` only through `PrefabRecipes` or a spec (`PrefabSpecs.BuildFromSpec`), called with the bridge's code tool (`execute_code` with MCP for Unity), not object by object with the bridge's generic tools. To change a prefab, rebuild it from its spec, or open it with `PrefabUtility.LoadPrefabContents`, change it with the recipes and save it. What the recipes can't build is reported, not improvised. |
| `EDIT-12` | After building or changing a prefab, the agent MUST run the prefab validator on it (`PrefabValidator.ValidateAsset`, or the `TEST-12` test with `run_tests`) and, when it came from a spec, `PrefabSpecs.Compare` MUST report no differences. It reports both results. |
| `EDIT-13` | With `editorBridge`, the agent MUST NOT run a package menu item or wizard through the bridge (`execute_menu_item`, or calling its menu method): most open a window or a modal dialog that the agent can't answer and that blocks the Editor. It calls the code API the rules name for that menu instead (`ScreenAuthoring` and `SpecialScreensCreator` with `screenSystem`, `GenerationCoordinator` with `fastIoC`), and when there is none, it does the step by the rules or tells the person which menu to use. Which menu maps to which API: `SCR-13`, `SCR-15`, `DI-09`, `DI-10`, `LIST-09`. |
| `EDIT-14` | A data asset (a ScriptableObject such as `{Feature}Config`) MUST be described by a spec next to it, `{Feature}Config.asset.json` with `type` (the full type name) and `values` (the serialized fields, enums as numbers), and MUST be built by `UnityArchitecture.Prefabs.AssetSpecs`, never written as YAML (`EDIT-06`). With `editorBridge`, the agent calls `AssetSpecs.Build(specPath)` through the code tool and fixes every problem it returns. Without one, `scripts/verify.sh` builds the specs that have no asset before compiling, or a person uses **Assets > Unity Architecture > Build Asset From Spec**. `AssetSpecs.Compare(specPath)` lists every value that differs. |


### Data asset spec

`Assets/Client/Inventory/Services/Resources/InventoryConfig.asset.json` builds `InventoryConfig.asset` next to it (`EDIT-14`). `values` uses the serialized field names, nested `[Serializable]` classes as objects, lists as arrays and enums as their number:

```json
{
    "type": "Client.Inventory.InventoryConfig",
    "values": {
        "weapons": [ { "id": 1, "displayName": "Iron Sword", "category": 0 } ],
        "potions": [ { "id": 201, "displayName": "Health Potion", "category": 2 } ]
    }
}
```

## Verification order

Run the cheapest deterministic check first, and stop at the first failure:

```
compile + analyzers → EditMode tests → generation status → Play mode check → report
```

| Step | With `editorBridge` (Editor open) | With `verifyScript` (Editor closed) | With neither |
|---|---|---|---|
| Compile and analyzers | `refresh_unity`, then read the Console; `verify-editor.sh` reads the compile result | `verify.sh`, exit code `1` lists errors | Not verified |
| EditMode tests | `run_tests` through the bridge; `verify-editor.sh` reads the result | `verify.sh` | Not verified |
| Generation status | Read `GenerationStatus.json` | `verify.sh` reads it | Read the file. It may be stale |
| Play mode check | Automate it (`EDIT-07`) | Manual step for the developer | Manual step for the developer |

## Automatic verification

The automatic checks that run when an agent finishes belong to the optional enforcement package, not to these rules. Their behavior and their rule IDs are in that package's documentation.

## Reporting back

End every report with what each tool verified:

```
Verified: compile and analyzers (verify.sh), 14 EditMode tests passed, GenerationStatus.json status 0
Not verified: Play mode check for TrophyRoom (manual)
```
