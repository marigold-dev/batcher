#! /usr/bin/env bash

set -e

RPC_NODE=https://ghostnet.tezos.marigold.dev/

post_rate_contract () {
  quote_data=$(curl --silent https://api.tzkt.io/v1/quotes/last)

  timestamp=$(echo $quote_data | jq '.timestamp' | xargs)

  xtz_usdt_price=$(echo $quote_data | jq '.usd' | xargs)
  xtz_tzBTC_price=$(echo $quote_data | jq '.btc' | xargs)

  # Regrex for the scientific notation. I.e, 1.2E-05
  notation_regrex="E|e"

  if [[ "$xtz_usdt_price" =~ $notation_regrex ]]; then 
    xtz_usdt_price=$(echo "$xtz_usdt_price" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
  fi 

  if [[ "$xtz_tzBTC_price" =~ $notation_regrex ]]; then 
    xtz_tzBTC_price=$(echo "$xtz_tzBTC_price" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
  fi 


  round_tzBTC_usdt_price=$(echo "scale=8; $xtz_tzBTC_price * 100000000 / $xtz_usdt_price" | bc)
  echo $round_tzBTC_usdt_price
  # Get current exchange pair

  current_exchange_pair=$(tezos-client run view get_current_exchange_pair on contract $1)

  # Compute exchange rate and post this rate to the batcher contract
  tzBTC_token="Pair (Pair (Some \"KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG\") 8) \"tzBTC\""
  USDT_token="Pair (Pair (Some \"KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm\") 6) \"USDT\""
  timestamp=$(date +%s)

  if [[ "$current_exchange_pair" =~ "tzBTC/USDT" ]]; then 
    round_tzBTC_usdt_price=$(echo "scale=0; $xtz_usdt_price * 100000000 / $xtz_tzBTC_price" | bc)
    tezos-client --endpoint $RPC_NODE transfer 0 from bob to $1 \
      --entrypoint post \
      --arg "Pair (Pair (Pair -8 $round_tzBTC_usdt_price) (Pair (Pair 1 ($tzBTC_token)) ($USDT_token))) $timestamp" \
      --burn-cap 2
  elif [[ "$current_exchange_pair" =~ "USDT/tzBTC" ]]; then
    round_usdt_tzBTC_price=$(echo "scale=0; $xtz_tzBTC_price * 100000000 / $xtz_usdt_price" | bc)
    tezos-client --endpoint $RPC_NODE transfer 0 from bob to $1 \
      --entrypoint post \
      --arg "Pair (Pair (Pair -8 $round_usdt_tzBTC_price) (Pair (Pair 1 ($USDT_token)) ($tzBTC_token))) $timestamp" \
      --burn-cap 2
  fi 
}

case "$1" in
post-rate-contract)
  contract=$2
  post_rate_contract $contract
  ;;
esac   