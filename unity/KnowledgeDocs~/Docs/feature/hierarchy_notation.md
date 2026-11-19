# How a hierarchy is described

The rules and handoffs describe prefabs with this notation:

| Form | Meaning |
|---|---|
| `Name (UnityType)` | GameObject with a Unity component |
| `Name (UnityType: setting)` | The same, with a required setting |
| `Name [ProjectType]` | GameObject with project MonoBehaviours |
| `Name (UnityType) [ProjectType]` | Both |

```text
TrophyRoomMain [MainRoomLoadController, MainRoomStateView]
├── Header
│   ├── TitleText (TextMeshProUGUI)
│   └── Close
│       ├── UI Content
│       └── Action (Image: alpha 0) [CloseController]
├── Content
└── Footer
```

> [!NOTE]
> Pure C# Models never appear in a hierarchy: they aren't on any GameObject.
