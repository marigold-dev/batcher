#! /usr/bin/env bash

set -e

while getopts u:t:b: flag
do
  case "${flag}" in
    c) CTEZ_address=${OPTARG};;
    e) EURL_address=${OPTARG};;
    k) KUSD_address=${OPTARG};;
    t) tzBTC_address=${OPTARG};;
    u) USDT_address=${OPTARG};;
    b) batcher_address=${OPTARG};;
  esac
done

post_rate_contract () {
  quote_data=$(curl --silent https://api.tzkt.io/v1/quotes/last)

  timestamp=$(echo $quote_data | jq '.timestamp' | xargs)

  xtz_usdt_price=$(echo $quote_data | jq '.usd' | xargs)
  xtz_tzBTC_price=$(echo $quote_data | jq '.btc' | xargs)
  xtz_EURL_price=$(echo $quote_data | jq '.eur' | xargs)

  # Regrex for the scientific notation. I.e, 1.2E-05
  notation_regrex="E|e"

  if [[ "$xtz_usdt_price" =~ $notation_regrex ]]; then
    xtz_usdt_price=$(echo "$xtz_usdt_price" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
  fi

  if [[ "$xtz_tzBTC_price" =~ $notation_regrex ]]; then
    xtz_tzBTC_price=$(echo "$xtz_tzBTC_price" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
  fi

  if [[ "$xtz_EURL_price" =~ $notation_regrex ]]; then
    xtz_EURL_price=$(echo "$xtz_EURL_price" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
  fi

  # Get current rate for tzBTC/USDT
  round_tzBTC_usdt_price=$(echo "scale=0; $xtz_usdt_price * 100000000 / $xtz_tzBTC_price" | bc)
  # Get current rate for tzBTC/EURL
  round_tzBTC_EURL_price=$(echo "scale=0; $xtz_EURL_price * 100000000 / $xtz_tzBTC_price" | bc)
  # Fake the current rate for tzBTC/CTEZ
  round_tzBTC_CTEZ_price=$(echo "scale=0; $xtz_usdt_price * 100000000 * 1.11 / $xtz_tzBTC_price" | bc)

  # Compute exchange rate and post this rate to the batcher contract
  CTEZ_token="Pair (Pair (Some \"$CTEZ_address\") 6) (Pair \"\" (Some \"FA1.2 token\"))"
  EURL_token="Pair (Pair (Some \"$EURL_address\") 6) (Pair \"tzBTC\" (Some \"FA2 token\"))"
  KUSD_token="Pair (Pair (Some \"$KUSD_address\") 18) (Pair \"tzBTC\" (Some \"FA1.2 token\"))"
  tzBTC_token="Pair (Pair (Some \"$tzBTC_address\") 8) (Pair \"tzBTC\" (Some \"FA1.2 token\"))"
  USDT_token="Pair (Pair (Some \"$USDT_address\") 6) (Pair \"USDT\" (Some \"FA2 token\"))"
  timestamp=$(date +%s)

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint post \
    --arg "Pair (Pair (Pair $round_tzBTC_usdt_price 100000000) (Pair (Pair 1 ($tzBTC_token)) ($USDT_token))) $timestamp" \
    --burn-cap 2

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint post \
    --arg "Pair (Pair (Pair $round_tzBTC_EURL_price 100000000) (Pair (Pair 1 ($tzBTC_token)) ($EURL_token))) $timestamp" \
    --burn-cap 2

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint post \
    --arg "Pair (Pair (Pair $round_tzBTC_usdt_price 100000000) (Pair (Pair 1 ($tzBTC_token)) ($KUSD_token))) $timestamp" \
    --burn-cap 2

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint post \
    --arg "Pair (Pair (Pair $round_tzBTC_CTEZ_price 100000000) (Pair (Pair 1 ($tzBTC_token)) ($CTEZ_token))) $timestamp" \
    --burn-cap 2
}

while true
do
	post_rate_contract $batcher_address
	sleep 120
done
