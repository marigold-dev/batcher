# Design document for the 0-slippage DEX POC

The aim of the 0-slippage dex is to enable users to deposit tokens for swap orders at the current Oracle price for a given pair.  The order will then be matched against an opposing order with no slippage in the price (up to a defined tolerance - +- 2bps).  If no order is found to totally fill the order (or partially fill) the order will be expired and the deposits returned.

The first PoC will be a very simple contract that will make the following assumptions/caveats.

- Only two pairs supported - XTZ/USDT and USDT/tzBTC
- No UI, contract will be originated and triggered using tezos-client
- Order book will not be visible
- Swap expiry will be static (this might change in later iterations)
- Tolerance is not included, swaps will only be exactly matched

## Exchange Rate Pricing Flow

For the initial PoC there will be a simple posting mechanism to supply the contract with current (Oracle type) exchange rates that will be used by the swap matching process.

A poster script/binary will periodically query a price source and post the rates to the contract. For the initial PoC the contract will keep a history of rates, this is purely for debugging during the PoC phase - this could be dropped at a later stage.

```mermaid
flowchart LR
   poster<--> | API call| price-source[(Source of Rates)]
   poster-->| via tezos-client| post(%POST)
   subgraph 0-slip-contract
   post(%POST) --> current-rates
   post(%POST) --> historic-rates
   end
```

Exchange rates are posted in the following format:

```json
{
  quote = {
    token_price = {
      token = {
        name = "XTZ";
      };
      value = 1;
      when = <timestamp>
    };
  };
  base = {
    token_price = {
      token = {
        name = "USDT";
        address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
      };
      value = 1.90;
      when = <timestamp>
    };
  }
}
```


## Swap Order Flow

A swap order can be place don the contract by depositing the token (or XTZ) that is required to be swapped.  The swap order remains in existence up until a predefined expiry from the point the order was placed or until a partial or matching order is found.

As there is no UI for the simple PoC, all swap order will be placed via the tezos-client.

### Total match

If an exact 'total' matched order is found the matching code triggers the redemption of the tokens in opposing directions from the treasury so it fulfils the swap orders.

```mermaid
sequenceDiagram
    participant UserA
    participant UserB
    participant SWAP
    participant treasury
    participant matching
    UserA-->>SWAP: swap_order(X XTZ at Y for USDT at Z)
    SWAP-->>treasury: deposit (X XTZ)
    UserB-->>SWAP: swap_order(R USDT at S for XTZ at T)
    SWAP-->>treasury:  deposit (R USDT)
    loop OrderMatching
        matching->>matching: match find prices and amounts - TOTAL match
    end
    matching->>treasury: redemption(R USDT to UserA)
    treasury-->>UserA: transfer(R USDT)
    matching->>treasury: redemption(X XTZ to UserB)
    treasury-->>UserB: transfer(X XTZ)
```

### Partial match

If a partial match is found, a partial redemption is triggered from the treasury to fulfil the swap orders.  Any remained swap amount remains and will go through future match cycles in order to try to match the remaining. If no match is found for the remaining amount, a redemption is triggered in the treasury to return the remaining amount to the user that placed the swap.

```mermaid
sequenceDiagram
    participant UserA
    participant UserB
    participant SWAP
    participant treasury
    participant matching
    UserA-->>SWAP: swap_order(X XTZ at Y for USDT at Z)
    SWAP-->>treasury: deposit (X XTZ)
    UserB-->>SWAP: swap_order(R USDT at S for XTZ at T)
    SWAP-->>treasury:  deposit (R USDT)
    loop OrderMatching
        matching->>matching: match find prices and a partial match (50%) on XTZ amount - PARTIAL match
    end
    matching->>treasury: redemption(R USDT to UserA)
    treasury-->>UserA: transfer(R USDT)
    matching->>treasury: redemption(1/2 of X XTZ to UserB)
    treasury-->>UserB: transfer(1/2 of X XTZ)
    loop OrderMatching
        matching->>matching: match continues to try to find a matching order for the remaining 50% of XTZ deposited
        matching->>matching: no match found - remaining portion of order expired once expiry time is reached
    end
    matching->>treasury: redemption(1/2 of X XTZ to UserA)
    treasury-->>UserA: transfer(1/2 of X XTZ)
```

### No match

If no match is found by the time the swap order expires, a redemption will be triggered to return the deposited amount to the user that placed the swap.

```mermaid
sequenceDiagram
    participant UserA
    participant UserB
    participant SWAP
    participant treasury
    participant matching
    UserA-->>SWAP: swap_order(X XTZ at Y for USDT at Z)
    SWAP-->>treasury: deposit (X XTZ)
    UserB-->>SWAP: swap_order(R USDT at S for XTZ at T)
    SWAP-->>treasury:  deposit (R USDT)
    loop OrderMatching
        matching->>matching: no matching orders can be found - NO match
        matching->>matching: orders are expired once expiry time is reached
    end
    matching->>treasury: redemption(R USDT to UserB)
    treasury-->>UserB: transfer(R USDT)
    matching->>treasury: redemption(X XTZ to UserA)
    treasury-->>UserA: transfer(X XTZ)
```

## Testing

For the PoC, the minimal set of tests to be completed on a testnet deployment for the contract to be considered working are as follows:

> The test plan should be run on the deployed contract for both initially supported pairs - XTZ/USDT and USDT/tzBTC,

### Scenario 1.   Simple Matching Swap

#### Setup:
  - Update Oracle price for swap.
  - Place equal and opposing swaps from different wallets at exact price and correct amounts

#### Result:
- The swaps should match and the treasury should redeem the correct amounts to the respective wallets

### Scenario 2.   Simple Non Matching Swap

#### Setup:
  - Update Oracle price for swap.
  - Place first swap
  - Update oracle price again
  - Place opposing swap from a different wallet at a different price

#### Result:
- The swaps should not match and deposits be returned correctly after expiry

### Scenario 3.   Partial Matching Swap

#### Setup:
  - Update Oracle price for swap.
  - Place first swap
  - Place equal and opposing swap from a different wallet at the same price but differing amount.

#### Result:
- The swaps should partially match and the treasury should redeem the amounts correctly
- Any remaining non matched amount should be redeemed to the correct wallet after swap expiry


