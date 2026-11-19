# Update the rules

```bash
bash .ai/templates/scripts/update.sh
```

It updates `.ai`, refreshes the copied files you didn't change, and lists the ones you did. Then ask:

```text
The .ai rules were updated. Read .ai/CHANGELOG.md and tell me what changed that affects this project's code.
```

> [!WARNING]
> Never edit files inside `.ai`: the next update overwrites them. Project rules go in the root `AGENTS.md`.
