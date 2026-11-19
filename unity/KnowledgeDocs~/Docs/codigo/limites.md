# Límites de tamaño

**El objetivo es lo que escribes; el límite es un stop en code review.**

| | Objetivo | Límite | Al llegar |
|---|:---:|:---:|---|
| Líneas por método | 12 | <color=#F85149>**15**</color> | Extrae un método con nombre |
| Líneas por clase | 120 | <color=#F85149>**200**</color> | Divide por responsabilidad |
| Parámetros | 2 | <color=#F85149>**3**</color> | Crea una clase de parámetros |
| Ancho de línea | | <color=#F85149>**120**</color> | Parte la línea |

> [!NOTE] Cómo se cuenta
> Líneas del cuerpo, sin líneas en blanco ni líneas con solo una llave. La clase cuenta todo. Aplica también a constructores y métodos de Unity. Solo tests y código generado están exentos.

Un método se queda en **un nivel de abstracción**: o coordina pasos con nombre, o hace un paso de bajo nivel.
