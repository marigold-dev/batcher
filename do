#!/usr/bin/env bash
set +x

OP=$1
ADDROROP=$2
NAME="0slip"
BUILDDIR="out"

usage(){
    echo "=============================================================="
    echo "./do <op>"
    echo "=> where:"
    echo "=> op = build.                Build compiles the ligo $NAME contract and storage"
    echo "=> op = dryrun <endpoint op>  Performs a dry-run against the $NAME contract"
    echo "=> op = deploy <address>.     Deploys the smart contract for the passed user address"
}

if [ -z "$OP" ]
then
    echo "No operation entered."
    usage
    exit 1;
fi

fail_op(){
   echo "Unsupported operation"
   usage
}

make_out_dir(){
  mkdir -p out
}


build_storage() {
    echo "Compiling $NAME storage"
    make_out_dir
    ligo compile contract slip/$NAME.mligo -e  main -s cameligo -o $BUILDDIR/$NAME.tz
}

build_contract(){
    echo "Compiling $NAME contract"
    make_out_dir
    INITSTORAGE=$(<slip/storage/storage.mligo)
    ligo compile storage slip/$NAME.mligo "$INITSTORAGE" -s cameligo  -e main -o $BUILDDIR/$NAME-storage.tz
}

build(){
    build_contract
    build_storage
}


dryrun(){
 echo "Executing dry-run of contract"
 INITSTORAGE=$(<contract/src/storage/storage.mligo)
 ligo run dry-run slip/$NAME.mligo "$ADDROROP" "$INITSTORAGE" -s cameligo  -e  main

}

deploy(){

echo "Deploying contract"
INITSTORAGE=$(<slip/storage/storage.mligo)
tezos-client originate contract "" for "$ADDR" transferring 0tez from $ADDR running $NAME.tz --init "$INITSTORAGE" --burn-cap 2

}

case $OP in
  "build")
    build;;
  "dryrun")
    dryrun;;
   "deploy")
    deploy;;
   *)
    fail_op
esac

exit 0
