# Pre-condition : you have a faucet wallet, and you setting up your tezos-client on Jakartanet

### Compile the main contract

`ligo compile contract batcher/batcher.mligo --output-file batcher.tz --protocol jakarta`

### Compile the initial storage

`ligo compile expression cameligo --michelson-format text --init-file batcher/storage/initial_storage.mligo 'f()' > storage.tz`

### Deploy the contrat

`tezos-client originate contract mycontract transferring 0 from <your-faucet-account> running batcher.tz --init "$(cat storage.tz)" --burn-cap 6`

### Interact with it

note the address of the deployed contract, and go to https://better-call.dev/ then paste the address, you can interact with it easily.