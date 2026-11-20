# MVC

**Load when:** writing any Model, View or Controller. Open only the part the task needs.

Implements `ARCH-01` to `ARCH-04` and `ARCH-09` from [AGENTS.md](../AGENTS.md).

| Part | Covers | Rule IDs |
|---|---|---|
| [Layers](mvc/layers.md) | What a Model, View, Controller, Module and Connector are; the dependency matrix | |
| [Scopes](mvc/scopes.md) | Self-contained parts of a feature with one root | `SCOPE-01` to `-05` |
| [Where a Model lives](mvc/where-a-model-lives.md) | Common parent, injection or singleton; how each layer gets its references | `ROOT-01` to `-09` |
| [Model rules](mvc/models.md) | Queries, commands, events, configuration | `MODEL-01` to `-11` |
| [View rules](mvc/views.md) | Subscribing, rendering, root and inner Views | `VIEW-01` to `-07` |
| [Controller rules](mvc/controllers.md) | One input, one command | `CTRL-01` to `-06` |
| [Violation patterns](mvc/violations.md) | Common mistakes and their correct form | |
