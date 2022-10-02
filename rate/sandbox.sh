#! /usr/bin/env sh

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

  current_exchange_rate=$(tezos-client run view get_current_exchange_rate on contract $1)
  echo "Rate is $current_exchange_rate"

  # Compute exchange rate and post this rate to the batcher contract
  tzBTC_token="Pair (Pair (Some \"KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG\") 8) \"tzBTC\""
  USDT_token="Pair (Pair (Some \"KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm\") 6) \"USDT\""
  timestamp=$(date +%s)

  michelson=""  

  if [[ "$current_exchange_rate" =~ "tzBTC/USDT" ]]; then 
    round_tzBTC_usdt_price=$(echo "scale=0; $xtz_usdt_price * 100000000 / $xtz_tzBTC_price" | bc)
    michelson="Pair (Pair (Pair -8 $round_tzBTC_usdt_price) (Pair (Pair 1 ($tzBTC_token)) ($USDT_token))) $timestamp"
  elif [[ "$current_exchange_rate" =~ "USDT/tzBTC" ]]; then
    round_usdt_tzBTC_price=$(echo "scale=0; $xtz_tzBTC_price * 100000000 / $xtz_usdt_price" | bc)
    michelson="Pair (Pair (Pair -8 $round_usdt_tzBTC_price) (Pair (Pair 1 ($USDT_token)) ($tzBTC_token))) $timestamp"
  else
    round_usdt_tzBTC_price=$(echo "scale=0; $xtz_tzBTC_price * 100000000 / $xtz_usdt_price" | bc)
    michelson="Pair (Pair (Pair -8 $round_usdt_tzBTC_price) (Pair (Pair 1 ($USDT_token)) ($tzBTC_token))) $timestamp"
  fi 
  echo "Posting rate michelson" 
  echo $michelson


  tezos-client --endpoint $RPC_NODE transfer 0 from bob to $1 \
    --entrypoint post \
    --arg "$michelson" \
    --burn-cap 2
}

case "$1" in
post-rate-contract)
  contract=$2
  post_rate_contract $contract
  ;;
esac   