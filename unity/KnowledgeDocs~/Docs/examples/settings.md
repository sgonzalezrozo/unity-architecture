# Example: custom input (Settings)

One toggle prefab reused for every on/off setting, and a volume bar with drag. No `Toggle` or `Slider`.

```text
SettingsScreen [SettingsModel]
├── SettingRows
│   ├── MusicRow (SettingToggle.prefab: settingKey = Music)
│   ├── SoundRow (SettingToggle.prefab: settingKey = Sound)
│   └── VolumeRow [VolumeBarView]
│       ├── UI Content
│       │   ├── VolumeTrack (Image)
│       │   └── VolumeFill (Image: type Filled)
│       └── Action (Image: alpha 0) [DragVolumeController]
└── Footer [SaveAreaView]

SettingToggle.prefab [SettingToggleView]
├── UI Content
│   ├── EnabledRoot
│   └── DisabledRoot
└── Action (Image: alpha 0) [ToggleSettingController]
```

- One `enum SettingKey` and one array replace three identical classes.
- The serialized `SettingKey` is a **config value**: View and Controller may both have it without knowing each other.
- Adding a setting: one enum value, one array entry and one prefab instance.
- `SettingsModel` lives on the screen root: no installer needed.
