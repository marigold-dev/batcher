# Liquidity Bot

## Pre-requisites

To run the bot you will need to have an environment that has Node.js installed.

> The releases were developed and tested with v18.14.0 of Node.

## Installation

The release package can be downloaded from the releases pages of the repo in either zip or tar.xz formats. A hash.md for each format is supplied so that the contents of the file can be verified.

## Operation

Once the release has been downloaded and unpacked it can be run from the command line.

### Liquidity Modes

The liquidity bot allows deposits to be made automatically based on configuration.  There are two specific modes of liquidity:

- JIT (just-in-time):  This mode listens for trades in each batch and places an opposing deposit.
- ALWAYS-ON         :  This mode supplies a given deposit at batch open.

To run the bot simply specify the mode as the first argument.  The second argument should be the path to the configuration file:

Jit mode:
```bash
node index.js jit <path to config>
```

Alwys-on mode:
```bash
node index.js always-on <path to config>
```

### Liquidity configuration

Both modes use a configuration file that supplies rules for the deposits for one or more pairs. Examples of config files for mainnet and ghostnet are bundled with the release; they include the variables for the Batcher contract address, the address of a Tezos node and the relevant tzkt api address.

Example of ghostnet config file.

```json
{
  "batcher_address": "KT1VbeN9etQe5c2b6EAFfCZVaSTpiieHj5u1",
  "tezos_node_uri": "https://ghostnet.tezos.marigold.dev",
  "tzkt_uri_api": "https://api.ghostnet.tzkt.io",
  "token_pairs":  [
    {
      "name": "tzBTC/USDT",
      "side": "both",
      "buy_limit_per_batch": 0.02,
      "buy_tolerance": "worse",
      "sell_limit_per_batch": 200,
      "sell_tolerance": "oracle"
    },
    {
      "name": "tzBTC/EURL",
      "side": "either",
      "buy_limit_per_batch": 0.02,
      "buy_tolerance": "oracle",
      "sell_limit_per_batch": 220,
      "sell_tolerance": "better"
    }
  ]


}

```

More importantly, they contain the configuration of the liquidity provision for the token pairs.

```json
  "token_pairs":  [
    {
      "name": "tzBTC/USDT",
      "side": "both",
      "buy_limit_per_batch": 0.02,
      "buy_tolerance": "worse",
      "sell_limit_per_batch": 200,
      "sell_tolerance": "oracle"
    },
    {
      "name": "tzBTC/EURL",
      "side": "either",
      "buy_limit_per_batch": 0.02,
      "buy_tolerance": "oracle",
      "sell_limit_per_batch": 220,
      "sell_tolerance": "better"
    }
  ]

```

When running the bot, a user is free to only include the pairs they are interested in. For each pair, the configuration should include the name of the pair, the side one wishes to supply liquidity for, and the amount limit per batch and tolerance for each side.

### Name

The name of the pair should be the same as that specified in the `valid_swap` item in the Batcher contract storage.  At the time of writing this is either *tzBTC/USDT* or *tzBTC/EURL*.

### Side

The 'side'  configuration is the side that a user is interested in trading.  These can be:

- both - one can supply liquidity to both sides of a trade if one should choose.
- either - one can supply either side of a trade; *this is only a valid option for the 'jit' mode*.
- buy - only supply liquidity for the buy side of a given pair
- sell - only supply liquidity for the sell side of a given pair

### Limit Per Batch

The `buy_limit_per_batch` and `sell_limit_per_batch` configurations define the deposit size that will occur in any given batch.

### Tolerance

With the `buy_tolerance` and `sell_tolerance`, one can set their choice of price level for a given batch that one is willing to trade at.  These follow the usual Batcher conventions:

- worse - A worse price but a better chance of the order being filled
- oracle - Trade at the Oracle price accepted after the batch has closed
- better - A better price but less chance of being filled.

> The tolerances are ten basis points off a given future Oracle price.

## Redemption

In either mode the bot will redeem any holdings once a batch is cleared.
