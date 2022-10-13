.PHONY: test

LIGO_COMPILER_VERSION:=0.53.0
TEZOS_PROTOCOL:=kathmandu
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

define test_ligo
  $(LIGO_DOCKER) run test $(1) --protocol $(TEZOS_PROTOCOL)
endef

define compile_contract
    $(LIGO_DOCKER) compile contract $(1) -e  main -s cameligo -o $(2) --protocol $(TEZOS_PROTOCOL)
endef

define compile_storage
    $(LIGO_DOCKER) compile expression cameligo --michelson-format text --init-file $(1) 'f()' > $(2)
endef


build:
	$(call compile_contract,batcher/batcher.mligo, batcher.tz)
	$(call compile_storage,batcher/storage/initial_storage.mligo, batcher-storage.tz)
build-tzBTC:
	$(call compile_contract,token/main.mligo, tzBTC_token.tz)
	$(call compile_storage,token/storage/tzBTC_storage.mligo, tzBTC_token_storage.tz)
build-USDT:
	$(call compile_contract,token/main.mligo, USDT_token.tz)
	$(call compile_storage,token/storage/USDT_storage.mligo, USDT_token_storage.tz)
test-batcher:
	$(call test_ligo,batcher/test/test_batcher_sc.mligo)
test-orders:
	$(call test_ligo,batcher/test/test_orders.mligo)
test-math:
	$(call test_ligo,batcher/test/test_math.mligo)
test-tokens:
	$(call test_ligo,batcher/test/test_tokens.mligo)
