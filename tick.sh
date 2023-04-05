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

post_op (){

  sleep 5

  echo "Tick batcher contract"

  octez-client transfer 0 from oracle_account to $batcher_address \
    --entrypoint tick \
    --arg "{}" \
    --burn-cap 2


}

while true
do
	post_op
	sleep $FREQ
done
