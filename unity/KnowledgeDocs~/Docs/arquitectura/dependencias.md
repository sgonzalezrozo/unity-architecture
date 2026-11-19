# Quién conoce a quién

> [!RULE] ARCH-01
> Las dependencias van en **un solo sentido**. Views y Controllers nunca se referencian entre sí.

| | Models | Render | Input | Views | Controllers |
|---|:---:|:---:|:---:|:---:|:---:|
| **Model** | <color=#3FB950>Sí</color> | <color=#F85149>No</color> | <color=#F85149>No</color> | <color=#F85149>No</color> | <color=#F85149>No</color> |
| **View** | <color=#3FB950>Sí</color> | <color=#3FB950>Sí</color> | <color=#F85149>No</color> | Solo inner | <color=#F85149>No</color> |
| **Controller** | <color=#3FB950>Sí</color> | <color=#F85149>No</color> | <color=#3FB950>Sí</color> | <color=#F85149>No</color> | <color=#F85149>No</color> |

- *Render* = `Image`, `TextMeshProUGUI`... *Input* = `IPointer*`, `IDrag*`.
- Un Model puede referenciar además **assets de configuración**.
- Excepción: el **Module** de una feature también conoce a su **Connector**.

> [!CAUTION] Lo comprueba el compilador
> El analyzer `UA0001` falla el build si una capa conoce a otra que no debe.

**Ver también:** [Las piezas del backend](doc:backend.piezas) · [Los Models no forman ciclos](doc:arquitectura.sin_ciclos)
