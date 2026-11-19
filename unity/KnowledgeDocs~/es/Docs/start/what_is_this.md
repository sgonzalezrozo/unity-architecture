# Qué es esto

La versión **para personas** de las reglas que siguen los agentes (`AGENTS.md` y `architecture/`). Las reglas de agente son normativas y tienen IDs; aquí van explicadas, con ejemplos.

> [!TIP]
> El icono de documento de cada tarjeta abre la regla original de la que sale.

## Qué es obligatorio

| Qué | Estado |
|---|---|
| Invariantes de arquitectura (`ARCH-*`) | <color=#F85149>**Obligatorio en todo proyecto**</color> |
| Reglas de capas MVC | <color=#F85149>**Obligatorio en todo proyecto**</color> |
| Estándares de C# | <color=#F85149>**Obligatorio en todo proyecto**</color> |
| Unity, C#, uGUI, TextMeshPro | Runtime necesario |
| Fast IoC, UI Scroller, Screen System, UI Foundations, Addressables | <color=#3FB950>**Opcional**</color>: cambian la implementación, nunca la arquitectura |

## Alcance

Todo el código cliente **excepto la simulación de gameplay** (normalmente ECS). El código que hay detrás de un wrapper ECS → vista sí las sigue. Los packages y herramientas (UI Scroller, por ejemplo) no tienen por qué.

> [!IMPORTANT]
> Código que rompe un invariante **está mal aunque compile y funcione**.

**Por dónde seguir:** [Instalar las reglas](doc:start.install_rules) · [MVC en resumen](doc:architecture.mvc_overview) · [Crear un elemento de UI](doc:ui.create_ui) · [Carpetas](doc:feature.folders)
