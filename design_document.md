# Design document for the 0-slippage DEX POX

### This document aim to describe the big picture, the worklow of the POC, ie the interactions between the differents actors, the available entrypoints etc.

```mermaid
sequenceDiagram
    participant User
    participant AScript?
    participant 0slip_sc
    User->>0slip_sc: transaction(0slip_sc%swap token price amount)
    Note right of 0slip_sc: Clean the expiried orders (not sure about this one)
    Note right of 0slip_sc: Add in the treasury map, a relation between User's address and the amount he deposited
    Note right of 0slip_sc: Create an swap_order and push it into the orderbook
    loop UpdateExchangeRates
        AScript?->>SourceOfTruth: get datas about exchange_rate
        AScript?->>0slip_sc: transaction(0slip_sc%post_rate exchange_rate)
    end
    Note right of 0slip_sc:check if the new rate is valid
    Note right of 0slip_sc:archive the current rate
    Note right of 0slip_sc:update the current rate with the new one
    loop TriggerOrderMatchingAlgorithm
        AScript?->>0slip_sc: transaction(0slip_sc%Tick)
    end
    Note right of 0slip_sc:for each totally or partially matched order
    0slip_sc-->>User: redeem(amount)
```