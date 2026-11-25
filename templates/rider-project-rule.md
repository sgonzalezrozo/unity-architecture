# Project rules

Set this rule's type to **Always** in the Rider editor.

All project rules live in `.ai/AGENTS.md`. Read it before suggesting code, then open only the parts its routing table names for your task.

Non-negotiable, in case nothing else is loaded:

- Strict MVC: Models know only Models. Views know only Models and rendering components. Controllers know only Models and input interfaces.
- Events are `public event Action OnSomethingChanged;` with no parameters. Listeners pull from the Model.
- No `Button`, `Toggle`, `Slider` or `Dropdown`. Controllers implement `IPointer*` interfaces.
- Packages are optional. Read the project profile, `Logs/ai/profile.md` (run `bash scripts/ai-profile.sh` if it's missing), instead of reading the manifest. Where a rule depends on a package, its document has a fork: open only the file of the branch the profile names, never the others (`OPT-06`). When `Logs/ai/packs/` exists, read the pack for the task instead (`Logs/ai/packs/index.md`, `OPT-07`), and take scenes, installers and localization from `Logs/ai/project-facts.md`.
- ECS gameplay is out of scope. A scope is one root GameObject, and a feature can hold several. Models and Views sit on the scope root. A Model moves up only when shared, and Views render only inside their scope.
- Models have no serialized fields and form no cycles. Add no abstraction without a second use or a test need. Load nothing before it's needed.
- Views and Controllers cache Models with `GetComponentInParent`. Only a Model with no common parent, or one that persists, is injected through an `internal` field. Without a container, it is a singleton. Pure C# classes use the constructor.
- Never write `.prefab`, `.unity`, `.asset` or `.meta` files as text. A change is verified only by a tool (Unity MCP, the Unity CLI or `scripts/verify.sh`). See `.ai/architecture/EDITOR_TOOLS.md`.
