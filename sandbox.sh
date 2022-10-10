#! /usr/bin/env bash

set -e

RPC_NODE=https://kathmandunet.tezos.marigold.dev

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

  # Get current rate for tzBTC/USDT
  round_tzBTC_usdt_price=$(echo "scale=0; $xtz_usdt_price * 100000000 / $xtz_tzBTC_price" | bc)

  # Compute exchange rate and post this rate to the batcher contract
  tzBTC_token="Pair (Pair (Some \"KT1EGB9ZquErCN3dNvPurmNBuKCAi8pc1ce7\") 8) \"tzBTC\""
  USDT_token="Pair (Pair (Some \"KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF\") 6) \"USDT\""
  timestamp=$(date +%s)

  tezos-client transfer 0 from bob to $1 \
    --entrypoint post \
    --arg "Pair (Pair (Pair -8 $round_tzBTC_usdt_price) (Pair (Pair 1 ($tzBTC_token)) ($USDT_token))) $timestamp" \
    --burn-cap 2
}

while true
do
	post_rate_contract KT1FCUp4kN9DziLmiRLMqDnuhBbGSwwoYHD4
	sleep 5
done