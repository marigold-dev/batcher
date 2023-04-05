#! /usr/bin/env bash

set -e

while getopts b:f: flag
do
  case "${flag}" in
    b) batcher_address=${OPTARG};;
    f) frequency=${OPTARG};;
  esac
done

FREQ=$(($frequency))

# declare -a TICKERS=("tzBTC-USDT" "EURL-tzBTC")
declare -a TICKERS=("tzBTC/USDT" "EURL-tzBTC")

tick_ticker(){

  echo "Tick batcher contract ticker ${1} - $batcher_address"

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint tick \
    --arg "\"${1}\"" \
    --burn-cap 2

}

post_op (){

for i in "${TICKERS[@]}"
do
   : 
   tick_ticker "$i"
  sleep 5
done

}



while true
do
	post_op
	sleep $FREQ
done
