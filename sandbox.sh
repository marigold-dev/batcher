#! /usr/bin/env bash

set -e

RPC_NODE=http://localhost:20000

tezos-client () {
  docker exec -t 0_slip_flextesa tezos-client "$@"
}

ligo-client () {
  docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.47.0 "$@"
}

deploy_contract () {
  echo "Deploying new $1 contract"

  # Compiles an initial storage for a given contract to a Michelson expression.
  # The resulting Michelson expression can be passed as an argument in a transaction which originates a contract.
  storage=$(ligo-client compile storage "$2" "$3")

  # Compiles a contract to Michelson code.
  # Expects a source file and an entrypoint function.
  contract=$(ligo-client compile contract "$2")

  echo "Originating $1 contract"
  sleep 2
  tezos-client --endpoint $RPC_NODE originate contract "$1" \
    transferring 0 from bob \
    running "$contract" \
    --init "$storage" \
    --burn-cap 2 \
    --force
}

deploy_treasury_contract () {
  treasury="treasury/main.mligo"

  # Get the treasury storage for a seperate module.
  storage_dir="data/treasury/storage.mligo"
  treasury_storage=$(cat "$storage_dir")

  deploy_contract "treasury" "$treasury" "$treasury_storage"
}

deposit_treasury_contract () {
  deposit_address=$(jq '.deposited_token.address' $1 | xargs)
  deposit_token_name=$(jq '.deposited_token.name' $1 | xargs)
  deposit_value=$(jq '.deposited_token.value' $1 | xargs)

  base_token_address=$(jq '.exchange_rate.base.address' $1 | xargs)
  base_token_name=$(jq '.exchange_rate.base.name' $1 | xargs)
  base_token_value=$(jq '.exchange_rate.base.value' $1 | xargs)
  base_token_timestamp=$(jq '.exchange_rate.base.timestamp' $1 | xargs)

  quote_token_address=$(jq '.exchange_rate.quote.address' $1 | xargs)
  quote_token_name=$(jq '.exchange_rate.quote.name' $1 | xargs)
  quote_token_value=$(jq '.exchange_rate.quote.value' $1 | xargs)
  quote_token_timestamp=$(jq '.exchange_rate.quote.timestamp' $1 | xargs)
 
  deposited_token="Pair (Pair \"$deposit_address\" \"$deposit_token_name\") $deposit_value"

  base_value="Pair (Pair (Pair \"$base_token_address\" \"$base_token_name\") $base_token_value) \"$base_token_timestamp\""
  quote_value="Pair (Pair (Pair \"$quote_token_address\" \"$quote_token_name\") $quote_token_value) \"$quote_token_timestamp\""
  exchange_rate="Pair ($base_value) ($quote_value)"

  tezos-client --endpoint $RPC_NODE transfer 0 from bob to treasury \
  --entrypoint deposit --arg "Pair ($deposited_token) ($exchange_rate) " \
  --burn-cap 2
}

redeem_treasury_contract () {
  redeem_address=$(jq '.redeemed_token.address' $1 | xargs)
  redeem_token_name=$(jq '.redeemed_token.name' $1 | xargs)
  redeem_value=$(jq '.redeemed_token.value' $1 | xargs)

  base_token_address=$(jq '.exchange_rate.base.address' $1 | xargs)
  base_token_name=$(jq '.exchange_rate.base.name' $1 | xargs)
  base_token_value=$(jq '.exchange_rate.base.value' $1 | xargs)
  base_token_timestamp=$(jq '.exchange_rate.base.timestamp' $1 | xargs)

  quote_token_address=$(jq '.exchange_rate.quote.address' $1 | xargs)
  quote_token_name=$(jq '.exchange_rate.quote.name' $1 | xargs)
  quote_token_value=$(jq '.exchange_rate.quote.value' $1 | xargs)
  quote_token_timestamp=$(jq '.exchange_rate.quote.timestamp' $1 | xargs)
 
  redeemed_token="Pair (Pair \"$redeem_address\" \"$redeem_token_name\") $redeem_value"

  base_value="Pair (Pair (Pair \"$base_token_address\" \"$base_token_name\") $base_token_value) \"$base_token_timestamp\""
  quote_value="Pair (Pair (Pair \"$quote_token_address\" \"$quote_token_name\") $quote_token_value) \"$quote_token_timestamp\""
  exchange_rate="Pair ($base_value) ($quote_value)"

  tezos-client --endpoint $RPC_NODE transfer 0 from bob to treasury \
  --entrypoint redeem --arg "Pair ($exchange_rate) ($redeemed_token)" \
  --burn-cap 2
}

case "$1" in
deploy-treasury-contract)
  deploy_treasury_contract 
  ;;
deposit-treasury-contract)
  deposit_data="data/treasury/deposit.json"
  deposit_treasury_contract $deposit_data
  ;;
redeem-treasury-contract)
  redeem_data="data/treasury/redeem.json"
  redeem_treasury_contract $redeem_data
  ;;
esac

