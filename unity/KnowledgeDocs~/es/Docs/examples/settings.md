# Ejemplo: input propio (Settings)

Un único prefab de toggle reutilizado para cada ajuste on/off, y una barra de volumen con drag. Sin `Toggle` ni `Slider`.

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

- Un `enum SettingKey` y un array reemplazan tres clases idénticas.
- El `SettingKey` serializado es un **valor de config**: View y Controller pueden tenerlo sin conocerse.
- Añadir un ajuste: un valor de enum, una entrada de array y una instancia del prefab.
- `SettingsModel` vive en la raíz de la pantalla: no hace falta installer.
