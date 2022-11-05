#! /usr/bin/env bash

set -e

while getopts u:t:b: flag
do
  case "${flag}" in
    u) USDT_address=${OPTARG};;
    t) tzBTC_address=${OPTARG};;
    b) batcher_address=${OPTARG};;
  esac
done

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
  tzBTC_token="Pair (Pair (Some \"$tzBTC_address\") 8) \"tzBTC\""
  USDT_token="Pair (Pair (Some \"$USDT_address\") 6) \"USDT\""
  timestamp=$(date +%s)

  octez-client transfer 0 from oracle_account to $1 \
    --entrypoint post \
    --arg "Pair (Pair (Pair -8 $round_tzBTC_usdt_price) (Pair (Pair 1 ($tzBTC_token)) ($USDT_token))) $timestamp" \
    --burn-cap 2
}

while true
do
	post_rate_contract $batcher_address
	sleep 5
done
