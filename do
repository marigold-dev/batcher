#!/usr/bin/env bash
set +x

OP=$1
ADDROROP=$2
NAME="batcher"
BUILDDIR="out"
PROTOCOL="jakarta"

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


build_contract() {
    echo "Compiling $NAME contract"
    make_out_dir
    ligo compile contract batcher/$NAME.mligo -e  main -s cameligo -o $BUILDDIR/$NAME.tz --protocol $PROTOCOL
}

build_storage(){
    echo "Compiling $NAME storage"
    make_out_dir
    ligo compile expression cameligo --michelson-format text --init-file $src/batcher/storage/initial_storage.mligo 'f()' > $BUILDDIR/${NAME}_storage.tz
}

build(){
    build_contract
    build_storage
}


dryrun(){
 echo "Executing dry-run of contract"
 build
 ligo run dry-run batcher/$NAME.mligo "$ADDROROP" "$(cat $BUILDDIR/$NAME_storage.tz)" -s cameligo  -e  main

}

deploy(){
build
echo "Deploying contract"
tezos-client originate contract "" for "$ADDR" transferring 0tez from $ADDR running $NAME.tz --init "$(cat $BUILDDIR/$NAME_storage.tz)" --burn-cap 6

}

case $OP in
  "build")
    build;;
  "build_contract")
    build_contract;;
  "build_storage")
    build_storage;;
  "dryrun")
    dryrun;;
   "deploy")
    deploy;;
   *)
    fail_op
esac

exit 0
