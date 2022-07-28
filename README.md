# 0-slip

## The treasury contract

This contract demonstrates the relations between the deposited tokens and the swapped tokens. Whenver a person deposits an amount of tokens, the contract caculates the swapped tokens based on the current exchange rate and store the deposited and swapped tokens.

## Get started 

The process is represented below

```
# Run docker containers
docker-compose up -d 
```

```
# Deploy the treasury contract
./sandbox.sh deploy-treasury-contract

# Deposit an amount of tokens
./sandbox.sh deposit-treasury-contract

# Redeem an amount of tokens
./sandbox.sh redeem-treasury-contract
```

## Contribution

Please refer to the `treasury/sandbox.sh` for more information
