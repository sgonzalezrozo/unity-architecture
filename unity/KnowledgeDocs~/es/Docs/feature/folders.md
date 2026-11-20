# Carpetas de una feature

`Assets/Client/` tiene una carpeta por feature. Una feature tiene una carpeta por pantalla, más `Services`.

```text
Assets/
├── Client/
│   ├── TrophyRoom/
│   │   ├── MainRoom/          C# y prefabs de la pantalla, juntos
│   │   ├── DetailsTrophy/
│   │   ├── Services/
│   │   └── Tests/         tests de la feature (Client.Tests.asmref)
│   ├── Shared/
│   └── Tests/             Client.Tests.asmdef
├── Art/        Arte fuente: texturas, sprites, materiales, VFX
├── Audio/      SFX, música, voz
├── Scenes/
└── Editor/
```

> [!RULE] ARCH-06
> El código de una feature y los prefabs hechos con él comparten carpeta. El arte fuente **no**.

> [!DONT]
> Subcarpetas `Scripts/`, `Prefabs/` o `Views/`. Una pantalla muy grande puede usar subcarpetas **por sección** (`Tabs/`, `Members/`), nunca por tipo de archivo.

> [!NOTE] Shared/
> Solo para lo que usan dos o más features y no pertenece a ninguna: prefabs reutilizables, diálogos, formatters.

**Ver también:** [La carpeta Services](doc:feature.services) · [Nombres](doc:feature.naming) · [Assembly definitions](doc:feature.asmdef)
