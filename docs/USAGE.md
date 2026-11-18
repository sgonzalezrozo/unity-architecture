# Usage with Claude Code

How to work with Claude Code once the rules are [installed](INSTALLATION.md): prompts that work, what the agent does with each, and what the Stop hook checks before it lets the agent finish.

You don't need to name the rules in your prompts. Claude Code loads `CLAUDE.md`, which loads `.ai/AGENTS.md` and your `AGENTS.md`; the agent reads the documents the routing table selects for the task. Name a rule ID only when you want a specific one applied or explained.

## Two ways to work

| | Editor open (MCP for Unity) | Editor closed |
|---|---|---|
| Compile | The agent calls `refresh_unity` and reads the Console | `scripts/verify.sh`, in batch mode |
| Tests | `run_tests` with a filter, then `get_test_job` | `VERIFY_TEST_FILTER="..." scripts/verify.sh` |
| Prefabs | Built and checked through `execute_code` (`EDIT-11`, `EDIT-12`) | Not built: the agent writes the handoff for you to build |
| Play mode check | Automated: enter Play mode, try the input, read the Console, exit (`EDIT-07`) | A manual step it reports for you |
| Stop hook | `scripts/verify-editor.sh` reads the results the Editor writes to `Logs/verify/` | `scripts/verify.sh` compiles, and runs the tests when they're due |

Work with the Editor open for anything with UI. The closed mode suits pure C# changes, CI, and machines without Unity open.

## What happens on every task

1. The agent classifies the request ([Agent workflow](../architecture/AGENT_WORKFLOW.md#task-classification)). A question gets an answer, a small change gets made, and a new feature, screen or refactor gets a plan first.
2. It runs [capability detection](../architecture/OPTIONAL_PACKAGES.md#capability-detection) on `Packages/manifest.json`, so its code uses Fast IoC, UI Scroller, Screen System or UI Foundations only when they're installed.
3. It writes the code, with Model tests first (`TEST-08`).
4. It compiles, reads every error and warning (`EDIT-02`), and fixes analyzer errors in the code, never by suppressing them (`EDIT-03`).
5. It runs the tests related to the change (`TEST-11`).
6. It ends with what each tool verified and what it didn't ([Reporting back](../architecture/EDITOR_TOOLS.md#reporting-back)).
7. When it stops, the hook checks again. If something fails, the hook sends the failure back, and the agent keeps working until the check passes or three attempts in a row fail.

## Examples

Each example is a prompt you can paste, followed by what the agent should do. Replace the names with your own.

### 1. Check the setup

```text
Check that this project is set up for the .ai rules: run capability detection and editor tool detection, refresh Unity, read the Console, run the prefab validator test, and tell me what each tool verified.
```

The agent reads `Packages/manifest.json` and lists every capability, calls `refresh_unity`, reads the Console, and runs `ClientPrefabsTests` through `run_tests`. Do this once after installing, and again whenever something in the setup changes.

### 2. Plan a new feature

```text
Plan a TrophyRoom feature: a screen with a list of trophies loaded from the backend, and a details popup with a claim button. Don't write code yet.
```

A new feature is "plan first, wait for approval". You get a short plan in the [plan format](../architecture/AGENT_WORKFLOW.md#plan): location, new files, where each Model lives, scopes, tests, capabilities and open questions. Answer the open questions, then:

```text
Approved. Build it.
```

The closest example is [Backend feature](../architecture/examples/01_BACKEND_FEATURE_TROPHY_ROOM.md).

### 3. Build a UI prefab with the Editor open

```text
Build a ClaimTrophyBanner for a new Rewards feature in Assets/Client/Rewards/ClaimTrophyBanner/: a background, a title text, a trophy icon, and a tap that claims the trophy. The Model counts claims, and the banner shows "Claimed" after the first tap. Write the handoff as a JSON spec, build it with PrefabSpecs.BuildFromSpec, validate and compare it, run the related tests, and do the Play mode check.
```

What the agent does, in order:

1. It writes the Model, View and Controller in `Assets/Client/Rewards/ClaimTrophyBanner/`, and the Model tests in `Assets/Tests/Rewards/`.
2. It compiles (`refresh_unity`) and runs the new tests.
3. It writes `ClaimTrophyBanner.json`, the handoff as a [prefab spec](../architecture/PREFABS.md#prefab-spec) (`HAND-06`).
4. It builds the prefab through `execute_code`:

   ```csharp
   // execute_code has no using directives: name the types in full.
   string json = System.IO.File.ReadAllText("Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.json");
   string prefab = "Assets/Client/Rewards/ClaimTrophyBanner/ClaimTrophyBanner.prefab";
   var built = UnityArchitecture.Prefabs.PrefabSpecs.BuildFromSpec(json, prefab);
   var checkedAgain = UnityArchitecture.Prefabs.PrefabValidator.ValidateAsset(prefab);
   var differences = UnityArchitecture.Prefabs.PrefabSpecs.Compare(json, prefab);
   ```

5. It reports the validator result and the differences, which must both be empty (`EDIT-12`), then reads the built hierarchy back (`EDIT-05`).
6. It runs `ClientPrefabsTests`, the validator as a test (`TEST-12`).
7. It enters Play mode, puts the prefab under a Canvas, taps the `Action`, checks that the Model and the View changed, reads the Console and exits.

What the spec can't express yet (a gradient, a sprite, font size or alignment) is reported, not improvised (`EDIT-11`). Set those by hand in the prefab afterwards, or wait for the spec to support them.

### 4. Change an existing prefab

```text
In the ClaimTrophyBanner, move the icon to the right side and make the banner 900 wide. Change the spec and rebuild it.
```

The agent edits the JSON spec, rebuilds it with `BuildFromSpec`, and reports the validator and `Compare` results. A change made by hand in the prefab shows up as a difference in `Compare`, so the spec stays the source of truth. For a prefab that has no spec, it opens the prefab with `PrefabUtility.LoadPrefabContents`, changes it with `PrefabRecipes` and saves it.

### 5. Validate every prefab

```text
Run the prefab validator on every prefab under Assets/Client and fix what it reports.
```

The agent runs `ClientPrefabsTests` (or **Tools > Unity Architecture > Validate Client Prefabs**). Each error names the prefab, the object and the rule (for example `PREFAB-09` for an `Action` that isn't invisible). It fixes the prefab by rebuilding it from its spec or changing it with the recipes, never by changing the validator or writing the prefab as text (`EDIT-06`).

### 6. Add a list

```text
Add an inventory list to Assets/Client/Inventory/MainInventory/ with tabs for Weapons and Armor, a selected item, and a details panel.
```

With `uiScroller` the agent uses a `Scroller<T>`, with a Slot Model on the slot prefab. Without it, it uses the [plain Unity list](../architecture/OPTIONAL_PACKAGES.md#list-without-ui-scroller). The closest example is [Filtered list](../architecture/examples/03_FILTERED_LIST_INVENTORY.md).

### 7. Replace a Toggle or a Slider

```text
Add a settings panel with a music toggle and a volume slider, without Toggle or Slider components.
```

`ARCH-05` forbids `Selectable` components, so the agent builds a View with On and Off roots plus a click Controller, and an `Image` fill plus a drag Controller. See [Custom input](../architecture/examples/02_CUSTOM_INPUT_SETTINGS.md).

### 8. Review code against the rules

```text
Review Assets/Client/Shop for rule violations. Cite the rule ID for each one, and don't change anything.
```

A review is answered directly. Each finding names the file, the line and the rule (`ARCH-04`, `VIEW-07`, `CTRL-03`...). Ask for fixes afterwards, one finding or all of them.

### 9. Fix a bug

```text
The coin balance doesn't update after a purchase. Find the cause and fix it, with a test that fails without the fix.
```

`TEST-04`: the fix comes with a test that fails without it. The agent runs that test and the tests of the classes it changed.

### 10. Work with the Editor closed

Close Unity, then:

```text
Add a ClaimTrophy command to TrophyRoomModule that rejects a trophy already claimed, with tests.
```

The agent verifies with `VERIFY_TEST_FILTER="TrophyRoomModuleTests" scripts/verify.sh`, and the hook compiles with `verify.sh` when it stops. If the change needs a prefab, it writes the handoff table for you to build, and reports the Play mode check as a manual step.

### 11. Explain a rule

```text
Why can't a View call a Model command? Explain VIEW-02 with an example from this project.
```

### 12. Update the rules

Ask Claude Code, or run it yourself:

```bash
bash .ai/templates/scripts/update.sh
```

It updates `.ai`, refreshes the copied files you didn't change, and lists the ones you did. Then:

```text
The .ai rules were updated. Read .ai/CHANGELOG.md and tell me what changed that affects this project's code.
```

## The Stop hook's messages

| Message | What the agent does |
|---|---|
| "Unity hasn't compiled the latest script changes" | Calls `refresh_unity`, reads the Console and stops again |
| "A prefab under Assets/Client changed after the prefab validator last ran" | Runs `ClientPrefabsTests` with `run_tests` and stops again |
| "The full EditMode suite is due" | Runs every EditMode test with `run_tests` (no filter). This happens at most every two hours |
| A prefab error with a rule ID | Rebuilds or fixes the prefab, and runs the validator again |
| A compile or analyzer error (`CS...`, `UA00..`) | Fixes the code |
| "Verify passed" | Nothing: the agent can finish |

The hook gives up after three failed attempts in a row and says so. Then read the failure yourself, or ask the agent to continue.

## Tips

- **Say where.** A path such as `Assets/Client/Rewards/ClaimTrophyBanner/` settles the feature, the folder and the namespace (`Client.Rewards`).
- **Say what the Model owns.** "The Model counts claims" tells the agent where the state lives and what to test.
- **Ask for a spec when you'll iterate on a prefab.** Changing a JSON file and rebuilding is repeatable; changing a prefab by hand isn't.
- **Keep project-only rules in your `AGENTS.md`**, such as "scene transitions go through `BaseStartScene.LoadSceneAsync`". The agent reads them on every task.
- **Read the last lines of each report.** "Verified" lists what a tool checked; "Not verified" lists what you still have to check.
