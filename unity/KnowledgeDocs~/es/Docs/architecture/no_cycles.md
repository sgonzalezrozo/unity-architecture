# Los Models no forman ciclos

> [!RULE] ARCH-09
> Si dos Models se necesitan, lo que comparten pasa a un **Model nuevo** que no necesita a ninguno de los dos. Un Model compartido nunca referencia el Model de una feature.

```flow
ShopModel -> WalletModel:rojo -> ShopModel
ShopModel -> CoinBalanceModel:verde
WalletModel -> CoinBalanceModel:verde
```

La primera fila es un ciclo (mal). Las otras dos: ambos dependen de un tercero (bien).

> [!NOTE]
> El analyzer `UA0014` detecta los ciclos al compilar.
