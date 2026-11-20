# UI patterns

**Load when:** building clickable elements, visual states, tabs, lists or layouts. Open only the part the task needs.

Patterns are mandatory. The packages that implement them are optional: where a pattern depends on one, its part has a fork (see [Optional packages](OPTIONAL_PACKAGES.md#forks)).

| Part | Covers | Rule IDs | Fork |
|---|---|---|---|
| [Clicks and input](ui/clicks.md) | `Button`, `Toggle`, `Slider` replacements; the `Action` object | `INPUT-01` to `-05` | `input` |
| [Visual states](ui/visual-states.md) | Mutually exclusive looks of one element | `STATE-01` to `-05` | `input` |
| [Tabs](ui/tabs.md) | Static tab content, one selected tab | | |
| [Lists](ui/lists.md) | Dynamic lists and grids | `LIST-01` to `-09` (in the branch) | `list` |
| [Layouts](ui/layouts.md) | Filling the space, layout groups | | |
