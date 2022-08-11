# Design document for the 0-slippage DEX POC

The aim of the 0-slippage dex is to enable users to deposit tokens with the aim of being swapped at a fair price with no slippage.  To enable this users will deposit tokens during a deposit window; all deposits during this window will be a 'batch'. Once the deposit window is over the 'batch' will be 'locked'. Deposits to the dex will not specify a price for the swap, they will specify an offset to whichever oracle price is received after the 'batch' is 'locked'; those offsets being 0, +10bps, or -10bps.  Once the batch is locked there will be a waiting window before the process starts to await an oracle price.  Upon receipt of the oracle price, the batch is terminated and the orders are cleared.

> For V1, the deposit window will be 10 mins and then a wait time of 2 minutes before awaiting the oracle price.
> Only the XTZ/USDT pair will be supported for V1

After the termination of the batch, the users that placed orders can retrieve their funds.  Either the user's order did not clear and they retrieve their original funds or the order cleared (totally or partially) and the get an execution of their order.


## Deposit

The deposit window is open for a finite time period.  During the time period users can deposit their tokens for a BUY or SELL order on the token pair along with an offset to the future received oracle price.

> For V1, deposit windows won't run sequentially, in that as soon as a deposit window closes another will open straight away.  Once the deposit window closes, users will need to wait for that batch to be cleared before another deposit window opens.

## Waiting

Once the deposit window has closed there will be a period of 2 minutes prior to awaiting an oracle price.  Once that period has elapsed the first received oracle price will close the batch and clearing will start.

## Clearing

The clearing process is the process of matching the orders to ensure that all users can trade at the fairest possible price.  Upon deposit there will be six categories of order.

### Side

Depending on whether you are buying so selling the pair you will either be on the BUY side of the SELL side. For the pair XTZ/USDT, XTZ is the base and USDT is the quote.  So if the XTZ/USDT rate was 1.9 you would get 1 unit of XTZ for 1.9 of USDT if I am buying the pair, i.e. on the BUY side.  If I am selling the pair, the inverse would be true.  The side of the trade is important to understand which token needs to be deposited in a given swap order.

### Tolerance

For any deposit, the user can specify the tolerance to the oracle price that they are willing to trade at. This means that each side can further be segregated into their tolerance levels; $Price_{oracle}-10bps$,  $Price_{oracle}$ ,  $Price_{oracle}+10bps$.

### Clearing Price

Considering that the amount of deposits for each category is different then we have six categories with a differing amount of tokens deposited for each tolerance.


| Deposits | P-10      | P         | P+10      |
|----------|:---------:|----------:|----------:|
| *BUY*    | X of USDT | Y of USDT | Z of USDT |
| *SELL*   | R of XTZ  | S of XTZ  | T of XTZ  |


An added complexity is that if I am will to buy at $Price_{oracle}+10bps$ then I will also be implicitly interested in buying at $Price_{oracle}$ and $Price_{oracle}-10bps$ as they are both cheaper levels if I am on the BUY side.





## Claiming
