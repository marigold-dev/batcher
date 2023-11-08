#! /usr/bin/env bash

set -e

while getopts b:f: flag
do
  case "${flag}" in
    b) batcher_address=${OPTARG};;
    m) market_maker_address=${OPTARG};;
    f) frequency=${OPTARG};;
  esac
done

FREQ=$(($frequency))

# declare -a TICKERS=("tzBTC-USDT" "EURL-tzBTC")
declare -a TICKERS=("BTCtz/USDT" "BTCtz/USDtz" "tzBTC/EURL" "tzBTC/USDT" "tzBTC/USDtz")

tick_ticker(){

  set +e
  echo "Tick batcher contract ticker ${1} - $batcher_address"

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint tick \
    --arg "\"${1}\"" \
    --burn-cap 2

  set -e
}

tick_mm(){

  set +e
  echo "Tick market maker contract - $market_maker_address"

  octez-client transfer 0 from oracle_account to $market_maker_address \
    --entrypoint tick \
    --arg "\"Unit\"" \
    --burn-cap 2

  set -e
}

post_op (){

for i in "${TICKERS[@]}"
do
   : 
   tick_ticker "$i"
  sleep 5
done

tick_mm

}



while true
do
	post_op
	sleep $FREQ
done
