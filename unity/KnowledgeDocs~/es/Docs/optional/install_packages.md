# Instalar packages

Todos son **opcionales**: cambian la implementación, nunca la arquitectura. Añadir uno al proyecto necesita aprobación (`OPT-03`).

**Window > Package Manager > + > Add package from git URL**, pega el URL (cada bloque tiene un botón **Copy**) y pulsa **Add**.

1. **Tools Core** primero, si vas a añadir Fast IoC, Screen System o UI Scroller: dependen de él y Unity no instala dependencias Git solo.

```text
https://github.com/sgonzalezrozo/unity-tools-core.git
```

2. Los que necesites:

**Fast IoC**: Inyección de dependencias (necesita Tools Core)

```text
https://github.com/sgonzalezrozo/unity-fast-ioc.git
```

**Screen System**: Pantallas, modales y navegación por capas (necesita Tools Core)

```text
https://github.com/sgonzalezrozo/unity-screen-system.git
```

**UI Scroller**: Listas recicladas (virtualizadas), grids, bento (necesita Tools Core)

```text
https://github.com/sgonzalezrozo/unity-ui-scroller.git
```

**UI Foundations**: Click Controller, estados visuales, gradientes

```text
https://github.com/sgonzalezrozo/unity-ui-foundations.git
```

**UI Tweens**: Animaciones de UI sin GC

```text
https://github.com/sgonzalezrozo/unity-ui-tweens.git
```

**Enhanced Console**: Consola con secciones y búsqueda

```text
https://github.com/sgonzalezrozo/unity-enhanced-console.git
```

**MCP for Unity**: El agente compila, testea y arma prefabs

```text
https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
```

> [!NOTE]
> Tras instalar uno, sus docs aparecen solos en esta ventana. Sus menús de setup: Fast IoC **Tools > FastIoC > Setup**, Screen System **Tools > Screen System > Setup**.

**Ver también:** [Packages opcionales](doc:optional.capabilities) · [Con package o sin él](doc:optional.equivalents)
