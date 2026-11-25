# FAQ

[← Back to README](../README.md)

## Project status

This is version `0.9.2`. The architecture and the code style are mandatory. [Fast IoC](https://github.com/sgonzalezrozo/unity-fast-ioc), [UI Scroller](https://github.com/sgonzalezrozo/unity-ui-scroller), [Screen System](https://github.com/sgonzalezrozo/unity-screen-system) and [UI Foundations](https://github.com/sgonzalezrozo/unity-ui-foundations) are optional: agents detect them, and use plain Unity forms when they're missing.

## How do I make AI coding agents follow an architecture in Unity?

Give them rules they can't miss, and checks they can't skip. Add this repository as `.ai/` and run its install script: it sets up the rules and the [verify loop](REFERENCE.md#how-verification-works) that checks every change. Instructions guide the agent, the verify loop checks the build and tests, and the optional [analyzers](../analyzers) turn the mechanical rules into compile errors.

## Does it work with Claude Code, Cursor, Copilot and Rider?

I use it with Claude Code, Copilot and Rider's AI Assistant. Claude Code reads `CLAUDE.md`, and Copilot and Rider read the [templates](../templates) you copy into their fixed paths. Cursor and Codex read the same kind of files (a Cursor rule template and `AGENTS.md`), but I haven't tested them yet.

## Does it work with Unity MCP?

Yes. With the Unity CLI (`unity mcp`) or MCP for Unity, the agent verifies through the open Editor and may build prefabs with editor tools. It still never writes prefab or scene YAML as text. See [Editor tools](../architecture/EDITOR_TOOLS.md).

## Which architecture does it use?

Strict MVC for uGUI: Models own state, Views render, Controllers receive input, and state flows by pull through parameterless events. No `Button`, `Toggle` or `Slider`, because each is a View and a Controller in one. ECS gameplay is out of scope.

## Do I need Fast IoC or the other packages?

No. [Fast IoC](https://github.com/sgonzalezrozo/unity-fast-ioc), [UI Scroller](https://github.com/sgonzalezrozo/unity-ui-scroller), [Screen System](https://github.com/sgonzalezrozo/unity-screen-system) and [UI Foundations](https://github.com/sgonzalezrozo/unity-ui-foundations) are optional. Agents detect them in `Packages/manifest.json` and use plain Unity forms when they're missing.

## Does it work with Unity 6, URP and HDRP?

It's written and tested against Unity 6 (`6000.3`). The rules cover uGUI code, so the render pipeline doesn't matter.

## How do I write an AGENTS.md or CLAUDE.md for a Unity project?

Start from this repository instead of a blank file. Add it as the `.ai/` submodule and run its install script, which creates a root `AGENTS.md` and `CLAUDE.md` that point to it, as the [installation guide](INSTALLATION.md) shows. Put rules that only apply to one project in that project's root `AGENTS.md`.

## Are there Cursor rules for Unity?

Yes. The optional enforcement package installs a Cursor rule, `.cursor/rules/unity-architecture.mdc`, that points Cursor to the rules in `.ai/AGENTS.md` and to your own in `PROJECT_RULES.md`. Without it, add an always-applied Cursor rule that says to read `.ai/AGENTS.md`.

## Is it free for commercial use?

Yes. It's MIT licensed.

## Does anyone else use it?

Not yet. It's version `0.9.2` by a single author, used only in my personal projects so far, and the rules still change. Feedback and issues are very welcome.

## Is there a sample project?

Not yet. A sample project that runs agents against the real packages, with the verify hook installed, will be published once it follows the current rules.
