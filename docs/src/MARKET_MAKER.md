# Community Market Maker

The community market maker is functionality to allow community members to provide liquidity to Batcher in return for a share of the trading fees.

## Providing liquidity

Any user can supply liquidity by depositing tokens into the market vault for that token. In return, the depositor will receive a market vault token that represents the user's share of the vault holdings. The market vault token can be redeemed at any time for the share of the holdings that currently exist in the market vault.

## Liquidity Injection

Liquidity in the market vault will be used by Batcher in batches where there is no market on one side of the trading pair. If liquidity is used then all trading fees in that batch will be given to the market vault for the token which was used to supply liquidity. These fees will be shared among the market vault participants according to the percentage of market value token a given user has. The amount of liquidity that is supplied to Batcher will be less than or equal to the position on the opposing size of the trade. This all depends on the liquidity available in the vault at a given time.

### Auto-redemption

When a batch is cleared that has used the liquidity in a market vault, the order that was placed to supply liquidity will be automatically redeemed. If the order was filled, the tokens redeemed will be stored in the market vault as foreign tokens. For example, if an order supplying liquidity from the tzBTC vault is filled and receives USDT upon redemption then the USDT will be allocated to the tzBTC vault as a foreign token.

### Auto-exchange of foreign tokens

If two vaults have a sufficient amount foreign tokens that can be exchanged with each other than Batcher will swap these amounts after receiving a next oracle price for the given pair of tokens. For example, assuming the tzBTC vault holds some USDT as foreign tokens and the USDT vault holds some tzBTC as foreign tokens then these will automatically be swapped between the market vaults using the oracle price.

## Redemption

A user can redeem a share of the market vault by depositing an amount of the market vault token which will be burned and the equivalent amount of tokens will be redeemed to the original deposit address. In addition to the redemption of tokens, the share of accumulated fees (in tez) will also will also be returned to the user.

### Redemption of foreign tokens

If the market vault holds a number of foreign tokens at the point of redemption then the holdings returned to the user will be the equivalent share of the market vault token along with an equivalent shares of foreign tokens held by the vault.

## Relationship between vaults.

There is NO relationship between the market vaults. Each vault is treated independently of each other and as such DOES NOT work like a constant sum or constant product liquidity pool in the traditional sense.

## Impermanent Loss

As stated the market vault doesn't work in the same way that a typical liquidity pool does. That said, there are potential loss vectors for a given provider, this will be due to the time that the vault has foreign tokens prior to swapping back to the market token.

- Loss due to missing out on price appreciation of non-stable token. As an example if a provider has deposited tzBTC in to the tzBTC vault and some of that liquidity has been used in the tzBTC/USDT pair then for an amount of time, the market vault will hold a portion of the original tzBTC as foreign tokens in the form of USDT. If during that period, the price of tzBTC were to rise then the provider would miss out on that price appreciation relative to just holding the original amount of tzBTC.
- Loss due to depreciation of the non-stable token. This is the equivalent to holding something like tzBTC and the price depreciates resulting in a loss.

Both types of loss are to some degree offset by the reward of trading fees from the use of liquidity within Batcher.

### Gain

Whilst a provider can incur losses by providing liquidity, there is also potential for gain (or at least the insulation against loss). Lets assume that some amoutn of the tzBTC vault has been used as liquidity in Batcher. The tzBTC vault will hold an amount of USDT as foreign tokens.  If, prior to those tokense bing swapped back to tzBTC, the price of tzBTC depreciates, then at the point of swap the vault will aquire more tzBTC than was previously swapped resulting in a net gain in the quantity of tzBTC.
