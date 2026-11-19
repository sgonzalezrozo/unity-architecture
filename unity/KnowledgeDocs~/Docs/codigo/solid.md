# SOLID y duplicación

- **Una responsabilidad** por clase.
- Depende de interfaces **en los bordes**: HTTP, archivos y SDKs detrás de una interfaz propia, como los Connectors.
- Composición antes que herencia. Una clase base nunca pregunta por sus derivadas.
- Polimorfismo antes que un `switch` por tipo. Un `switch` expression para un mapeo simple está bien.
- `private` por defecto; `{ get; private set; }` antes que setters públicos.

> [!RULE] Duplicación
> Una segunda copia de una regla o un cálculo **se extrae**. La estructura repetida (el patrón de suscripción de una View) está bien.

> [!NOTE]
> Sin abstracciones especulativas (`ARCH-10`).
