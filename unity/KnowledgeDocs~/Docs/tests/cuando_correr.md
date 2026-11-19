# Cuándo corren los tests

> [!RULE] TEST-11
> Antes de terminar un cambio corren los tests **relacionados**: los de las clases cambiadas o añadidas y los de quien las usa. La suite completa corre en el Stop hook como mucho cada dos horas.

> [!RULE] TEST-10
> Una pantalla nueva pasa un **check en Play mode**: abre, su input principal funciona y la Consola no tiene errores.

> [!RULE] TEST-12
> Todo prefab bajo `Assets/Client` pasa el validador de prefabs.
