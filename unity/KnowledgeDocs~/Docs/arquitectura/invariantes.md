# Las 11 reglas de arquitectura

Código que rompe una de estas **está mal aunque compile y funcione**.

| ID | En una frase |
|---|---|
| `ARCH-01` | Dependencias en un solo sentido: Views y Controllers conocen Models; Models solo Models |
| `ARCH-02` | Todo el estado vive en Models |
| `ARCH-03` | Las Views pintan, los Controllers reciben input |
| `ARCH-04` | Pull, nunca push: eventos sin parámetros |
| `ARCH-05` | Nada de `Button`, `Toggle`, `Slider`, `Dropdown` |
| `ARCH-06` | El código y sus prefabs comparten carpeta; el arte fuente no |
| `ARCH-07` | Lo que puede ser determinista, lo es |
| `ARCH-08` | Lo testeable tiene test |
| `ARCH-09` | Los Models no forman ciclos |
| `ARCH-10` | Sin abstracciones sin un segundo uso |
| `ARCH-11` | Haz lo mínimo; lo que no se usa no cuesta nada |

> [!TIP]
> Pulsa un ID para abrir su doc con ejemplos.
