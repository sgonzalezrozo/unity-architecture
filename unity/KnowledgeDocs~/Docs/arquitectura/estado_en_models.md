# Los Models son la verdad

> [!RULE] ARCH-02
> Todos los datos y todo el estado viven en Models. Views y Controllers no guardan nada más que referencias cacheadas.

> [!RULE] ARCH-03
> Las Views **pintan** y los Controllers **reciben input**. Una View no maneja input ni llama comandos. Un Controller no cambia nada visual.

> [!DONT]
> Un `bool isOpen` en una View, o un contador de clicks en un Controller.

> [!DO]
> Ese estado va en un Model, y la View lo lee.
