# Cómo se describe una jerarquía

Las reglas y los handoffs describen prefabs con esta notación:

| Forma | Significa |
|---|---|
| `Name (UnityType)` | GameObject con un componente de Unity |
| `Name (UnityType: ajuste)` | Igual, con un ajuste obligatorio |
| `Name [ProjectType]` | GameObject con MonoBehaviours del proyecto |
| `Name (UnityType) [ProjectType]` | Con ambos |

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
> Los Models C# puros nunca aparecen en una jerarquía: no están en ningún GameObject.
