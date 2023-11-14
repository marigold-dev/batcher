#! /usr/bin/env bash

set -e

while getopts b:m:f: flag
do
  case "${flag}" in
    b) batcher_address=${OPTARG};;
    m) market_maker_address=${OPTARG};;
    f) frequency=${OPTARG};;
  esac
done

FREQ=$(($frequency))


tick_ticker(){

  set +e
  echo "Tick batcher contract ticker ${1} - $batcher_address"

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint "tick" \
    --arg "Unit" \
    --burn-cap 2

  set -e
}

tick_mm(){

  set +e
  echo "Tick market maker contract - $market_maker_address"

  octez-client transfer 0 from oracle_account to $market_maker_address \
    --entrypoint "tick" \
    --arg "Unit" \
    --burn-cap 2

  set -e
}

post_op (){

tick_ticker
tick_mm
}



while true
do
	post_op
    sleep $FREQ
done
