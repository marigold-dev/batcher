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
  treasury="./main.mligo"
  treasury_storage=$(
     cat <<EOF
  {
  treasury = (Big_map.empty : Storage.Types.treasury);
  swapped_token = (Big_map.empty : Storage.Types.swapped_token);
}
EOF
  )

  deploy_contract "treasury" "$treasury" "$treasury_storage"
}

deposit_treasury_contract () {
  tezos-client --endpoint $RPC_NODE transfer 0 from bob to treasury \
  --entrypoint deposit --arg "Pair 200 (Pair 10 5)"  \
  --burn-cap 2
}

redeem_treasury_contract () {
  tezos-client --endpoint $RPC_NODE transfer 0 from bob to treasury \
  --entrypoint redeem --arg "Pair (Pair 10 5) 70" \
  --burn-cap 2
}

case "$1" in
deploy-treasury-contract)
  deploy_treasury_contract
  ;;
deposit-treasury-contract)
  deposit_treasury_contract
  ;;
redeem-treasury-contract)
  redeem_treasury_contract
  ;;
esac


