# Layouts adaptables

```text
ScreenRoot (llena el padre, VerticalLayoutGroup)
├── Header (alto fijo o preferido)
├── Content (flexible, llena el resto)
└── Footer (alto fijo o preferido)
```

- Los layouts **llenan el espacio** disponible y se adaptan a su contenedor.
- `LayoutGroup` con tamaños preferidos y flexibles, no posiciones fijas.
- Más de unos **5 niveles** de jerarquía es una señal de alarma.
- Prueba con varios aspect ratios.

> [!NOTE]
> Separa lo estático de lo dinámico. Lo dinámico es contenido de pestaña o una lista.
