# Guides on token deployment

## Prerequisites

You have a tezos node which is connected to testnet `network` like ghostnet or point octez-client to a public RCP node and owned a faucet wallet on this network.

## Compile these contracts

```console
$ make build-tzBTC # tzBTC
$ make build-USDT # USDT
$ make build-EURL # EURL
```

## Deploy these contracts to Jakarta network

```console
$ tezos-client originate contract tzBTC_token transferring 0 from %YOUR_ADDRESS% running tzBTC_token.tz --init "$(cat tzBTC_token_storage.tz)" --burn-cap 10 # Deployment for tzBTC

$ tezos-client originate contract USDT_token transferring 0 from %YOUR_ADDRESS% running USDT_token.tz --init "$(cat USDT_token_storage.tz)" --burn-cap 10 # Deployment for USDT

$ tezos-client originate contract EURL_token transferring 0 from %YOUR_ADDRESS% running EURL_token.tz --init "$(cat EURL_token_storage.tz)" --burn-cap 10 # Deployment for EURL
```

Finally, you can interact with the deployed contracts.
