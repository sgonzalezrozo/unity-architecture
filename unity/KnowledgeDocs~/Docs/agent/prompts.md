# Prompts that work

You don't need to name the rules: the agent loads `AGENTS.md` and what the task needs. Name an ID only when you want that specific rule.

| You want | Ask |
|---|---|
| Check the setup | *Check that this project is set up for the .ai rules: read the project profile (Logs/ai/profile.md) and list its forks and capabilities, refresh Unity, read the Console, run the prefab validator test.* |
| A plan | *Plan a TrophyRoom feature: a list of trophies from the backend and a details popup with a claim button. Don't write code yet.* |
| A review | *Review Assets/Client/Shop for rule violations. Cite the rule ID for each one, and don't change anything.* |
| A bug fix | *The coin balance doesn't update after a purchase. Fix it, with a test that fails without the fix.* |
| A rule explained | *Why can't a View call a Model command? Explain VIEW-02 with an example from this project.* |

## Tips

- **Say where:** a path such as `Assets/Client/Rewards/ClaimTrophyBanner/` settles the feature, folder and namespace.
- **Say what the Model owns:** "the Model counts claims" tells it where state lives and what to test.
- **Attach the look:** a PNG path (mockup or screenshot) settles colors, order and spacing.
- **Ask for a spec** when you'll iterate on a prefab.
- **Project-only rules** go in your root `AGENTS.md`, never inside `.ai`.
