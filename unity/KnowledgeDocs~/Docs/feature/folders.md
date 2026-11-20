# Feature folders

`Assets/Client/` has one folder per feature. A feature has one folder per screen, plus `Services`.

```text
Assets/
├── Client/
│   ├── TrophyRoom/
│   │   ├── MainRoom/          the screen's C# and prefabs, side by side
│   │   ├── DetailsTrophy/
│   │   ├── Services/
│   │   └── Tests/         the feature's tests (Client.Tests.asmref)
│   ├── Shared/
│   └── Tests/             Client.Tests.asmdef
├── Art/        Source art: textures, sprites, materials, VFX
├── Audio/      SFX, music, voice
├── Scenes/
└── Editor/
```

> [!RULE] ARCH-06
> A feature's code and the prefabs built from it share a folder. Source art **doesn't**.

> [!DONT]
> `Scripts/`, `Prefabs/` or `Views/` subfolders. A very large screen may use subfolders **by section** (`Tabs/`, `Members/`), never by file type.

> [!NOTE] Shared/
> Only for things two or more features use that belong to none of them: reusable prefabs, dialogs, formatters.

**See also:** [The Services folder](doc:feature.services) · [Naming](doc:feature.naming) · [Assembly definitions](doc:feature.asmdef)
