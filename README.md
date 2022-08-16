# Design document for the Batch Clearing DEX POC

The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss.  To enable this users will deposit tokens during a deposit window; all deposits during this window will be a 'batch'. Once the deposit window is over the 'batch' will be 'locked'. Deposits to the dex will not specify a price for the swap, they will specify an offset to whichever oracle price is received after the 'batch' is 'locked'; those offsets being 0, +10bps, or -10bps.  Once the batch is locked there will be a waiting window before the process starts to await an oracle price.  Upon receipt of the oracle price, the batch is terminated and the orders are cleared.

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


| Deposits | P-10bps   | P         | P+10bps   |
|----------|:---------:|----------:|----------:|
| *BUY*    | X of USDT | Y of USDT | Z of USDT |
| *SELL*   | R of XTZ  | S of XTZ  | T of XTZ  |


An added complexity is that if I am will to buy at $Price_{oracle}+10bps$ then I will also be implicitly interested in buying at $Price_{oracle}$ and $Price_{oracle}-10bps$ as they are both cheaper levels if I am on the BUY side.  The converse is true for the sell side in that if I sell for $Price_{oracle}-10bps$, then I would be willing to sell for the higher prices of $Price_{oracle}$ and $Price_{oracle}+10bps$.

#### Determining the clearing price

| Prices   | P-10bps          | P         | P+10bps          |
|----------|:----------------:|----------:|-----------------:|
| *BUY*    | P / 1.0001       | P         | P * 1.0001       |
| *SELL*   | 1.0001 / P       | 1/P       |  1/ (1.0001 * P) |


##### P-10bps level

Lets take the P-10bps sell level first.  All of the buy levels would be interested in buying at that price, so the clearing price at that level would be:

$$ CP_{P-10bps} = \min(X + Y + Z, R * \dfrac{ 1.0001 }{P})  $$


##### P level

Lets take the P sell level first.  Only the upper 2 buy levels would be interested in buying at that price, but the lower two SELL levels would be interested in selling so the clearing price at that level would be:

$$ CP_{P} = \min(Y + Z, (R+S) *  \dfrac{1}{P})  $$

##### P+10bps level

Lets take the P+10bps sell level first.  All of the sell levels would be interested in selling at that price, but only the upper BUY level would be interested in buying so the clearing price at that level would be:

$$ CP_{P-10bps} = \min(Z, (R+S+T) * \dfrac{1}{(P * 1.0001)})  $$

#### Illustrative Examples

If the Oracle price for XTZ/USDT is 1.9 and the tolerance is +/- 10 basis points, then the six price levels are:

| Price Levels | 	BUY  	| SELL    |
|--------------|:------:|:-------:|
|Price + 10bps |1.90019 |	0.52626 |
|Price         |	1.9   | 0.52631 |
|Price - 10bps | 1.89981|	0.52636 |

Assuming these levels we can determine some very basic illustrative examples of different market scenarios:


| MARKET |	AMOUNTS SKEW |	BUY X @ (P-) | BUY Y @ (P) | 	BUY Z @ (P+)	| SELL R @ (P-)	| SELL @ S (P)	| SELL T @ (P+)	| Orders cleared @ P-10bps	| Orders cleared @ P	| Orders cleared @ P+10bps	| Clearance Price |
|---|---|---|---|---|---|---|---|---|---|---|---|
|SELL PRESSUE	|CENTERED	|55	|100	|45	|1000	|1900	|900	|200	|155	|55	|P-10bps|
|SELL PRESSUE	|NEG	|100	|55	|45	|1900	|1000	|900	|200	|155	|100	|P-10bps|
|SELL PRESSUE	|POS	|45	|55	|100	|900	|1000	|1900	|200	|100	|45	|P-10bps|
|BUY PRESSURE	|CENTERED	|250	|100	|250	|95	|190	|95	|50	|150	|200	|P+10bps|
|BUY PRESSURE	|NEG	|250	|100	|250	|190	|95	|95	|100	|150	|200	|P+10bps|
|BUY PRESSURE	|POS	|250	|100	|250	|95	|95	|190	|50	|100	|200	|P+10bps|
|BALANCED	|CENTERED	|50	|101	|50	|95	|190	|95	|50	|150	|50|	P|
|BALANCED	|NEG	|101|	50|	50|	190|95|	95	|100|150|	101|	P|
|BALANCED	|POS	|50	|50	|101|	95|	95|	190	|50	|100|	50|	P|
|BALANCED	|OPPOSING (NEG)	|50	|50|	101|	190|	95|	95|	100|	100|	50|	P-10bps|
|BALANCED	|OPPOSING (POS)	|101	|50|	50|	95|	95|	190|	50|	100	|101|	P+10bps|

Once we now the clearing price we will know how many can be matched (some partially) and those will receive pro-rata execution of their orders.  For those that bid outside of the clearing price they will receive their deposits back when they claim.

> A Google [Sheet](https://docs.google.com/spreadsheets/d/1tWIQEVi2COW3UOH7BPbcNrqe77SsPqZVFqN7nfLe6mc/edit?usp=sharing) with these calculations in is available.
>
## Claiming

After clearing, users can claim their 'results', whether that be their original deposits, a partially matched order result or a fully filled order for the opposing token.
