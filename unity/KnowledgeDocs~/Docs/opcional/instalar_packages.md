# Instalar packages

Todos son **opcionales**: cambian la implementación, nunca la arquitectura. Añadir uno al proyecto necesita aprobación (`OPT-03`).

**Window > Package Manager > + > Add package from git URL**, en este orden:

1. **Tools Core** primero: los demás dependen de él y Unity no instala dependencias Git solo.

```text
https://github.com/sgonzalezrozo/unity-tools-core.git
```

2. Los que necesites:

| Package | Para qué | URL |
|---|---|---|
| Fast IoC | Inyección de dependencias | `https://github.com/sgonzalezrozo/unity-fast-ioc.git` |
| Screen System | Pantallas, modales y navegación por capas | `https://github.com/sgonzalezrozo/unity-screen-system.git` |
| UI Scroller | Listas recicladas (virtualizadas), grids, bento | `https://github.com/sgonzalezrozo/unity-ui-scroller.git` |
| UI Foundations | Click Controller, estados visuales, gradientes | `https://github.com/sgonzalezrozo/unity-ui-foundations.git` |
| UI Tweens | Animaciones de UI sin GC | `https://github.com/sgonzalezrozo/unity-ui-tweens.git` |
| Enhanced Console | Consola con secciones y búsqueda | `https://github.com/sgonzalezrozo/unity-enhanced-console.git` |
| MCP for Unity | El agente compila, testea y arma prefabs | `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity` |

> [!NOTE]
> Tras instalar uno, sus docs aparecen solos en esta ventana. Sus menús de setup: Fast IoC **Tools > FastIoC > Setup**, Screen System **Tools > Screen System > Setup**.

**Ver también:** [Packages opcionales](doc:opcional.capacidades) · [Con package o sin él](doc:opcional.equivalencias)
