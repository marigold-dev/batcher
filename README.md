# Design document for the 0-slippage DEX POC

The aim of the 0-slippage dex is to enable users to deposit tokens with the aim of being swapped at a fair price with no slippage.  To enable this users will deposit tokens during a deposit window; all deposits during this window will be a 'batch'. Once the deposit window is over the 'batch' will be 'locked'. Deposits to the dex will not specify a price for the swap, they will specify an offset to whichever oracle price is received after the 'batch' is 'locked'; those offsets being 0, +10bps, or -10bps.  Once the batch is locked there will be a waiting window before the process starts to await an oracle price.  Upon receipt of the oracle price, the batch is terminated and the orders are cleared.

> For V1, the deposit window will be 10 mins and then a wait time of 2 minutes before awaiting the oracle price.
> Only the USDT/tzBTC pair will be supported for V1

After the termination of the batch, the users that placed orders can retrieve their funds.  Either the user's order did not clear and they retrieve their original funds or the order cleared (totally or partially) and the get an execution of their order.


## Deposit

The deposit window is open for a finite time period.  During the time period users can deposit their tokens for a BUY or SELL order on the token pair along with an offset to the future received oracle price.



## Waiting

## Clearing

