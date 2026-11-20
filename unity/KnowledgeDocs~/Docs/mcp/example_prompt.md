# Example: ask for a prefab with the Editor open

```text
Build a ClaimTrophyBanner for a new Rewards feature in Assets/Client/Rewards/ClaimTrophyBanner/:
a background, a title text, a trophy icon, and a tap that claims the trophy. The Model counts
claims, and the banner shows "Claimed" after the first tap. Write the handoff as a JSON spec,
build it with PrefabSpecs.BuildFromSpec, validate and compare it, run the related tests, and do
the Play mode check.
```

What the agent does, in order:

1. Writes the Model, View and Controller in the folder, and the Model tests in `Assets/Client/Rewards/Tests/`.
1. Compiles (`refresh_unity`) and runs the new tests.
1. Writes `ClaimTrophyBanner.json`: a `UI Content` with background, title and icon, and the `Action` next to it.
1. Builds it through `execute_code` (`BuildFromSpec`, `ValidateAsset`, `Compare`).
1. Reports the validator and the differences (both empty) and reads the hierarchy back.
1. Runs the `ClientPrefabsTests` case for `Rewards`.
1. Enters Play mode, taps the `Action`, checks the Model and the View, reads the Console and exits.
