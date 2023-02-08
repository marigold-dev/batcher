.PHONY: test

LIGO_COMPILER_VERSION:=0.59.0
TEZOS_PROTOCOL:=lima
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

define test_ligo
  $(LIGO_DOCKER) run test $(1) --protocol $(TEZOS_PROTOCOL)
endef

define compile_contract
    $(LIGO_DOCKER) compile contract $(1) -e  main -s cameligo -o $(2) --protocol $(TEZOS_PROTOCOL)
endef

define compile_storage
    $(LIGO_DOCKER) compile expression cameligo -p $(TEZOS_PROTOCOL) --werror --init-file $(1) 'f()' > $(2)
endef

define clean_files
   rm -rf *.tz
endef

clean:
	$(call clean_files)
build:
	$(call clean_files)
	$(call compile_contract,batcher/batcher.mligo, batcher.tz)
	$(call compile_storage,batcher/storage/initial_storage_ghostnet.mligo, batcher-storage.tz)
build-lima:
	$(call clean_files)
	$(call compile_contract,batcher/batcher.mligo, batcher.tz)
	$(call compile_storage,batcher/storage/initial_storage_limanet.mligo, batcher-storage.tz)
build-tzBTC:
	$(call clean_files)
	$(call compile_contract,tokens/tzbtc/main.mligo, tzBTC_token.tz)
	$(call compile_storage,tokens/tzbtc/storage/tzBTC_storage.mligo, tzBTC_token_storage.tz)
build-USDT:
	$(call clean_files)
	$(call compile_contract,tokens/usdt/main.mligo, USDT_token.tz)
	$(call compile_storage,tokens/usdt/storage/USDT_storage.mligo, USDT_token_storage.tz)
build-CTEZ:
	$(call clean_files)
	$(call compile_contract,tokens/ctez/main.mligo, CTEZ_token.tz)
	$(call compile_storage,tokens/ctez/storage/CTEZ_storage.mligo, CTEZ_token_storage.tz)
build-KUSD:
	$(call clean_files)
	$(call compile_contract,tokens/kusd/main.mligo, KUSD_token.tz)
	$(call compile_storage,tokens/kusd/storage/KUSD_storage.mligo, KUSD_token_storage.tz)
build-EURL:
	$(call clean_files)
	$(call compile_contract,tokens/eurl/main.mligo, EURL_token.tz)
	$(call compile_storage,tokens/eurl/storage/EURL_storage.mligo, EURL_token_storage.tz)
test-batcher:
	$(call test_ligo,batcher/test/test_batcher_sc.mligo)
test-orders:
	$(call test_ligo,batcher/test/test_orders.mligo)
test-math:
	$(call test_ligo,batcher/test/test_math.mligo)
test-tokens:
	$(call test_ligo,batcher/test/test_tokens.mligo)
build-fa12-tzBTC:
	$(call compile_contract,fa12-token/main.mligo, tzBTC_fa12_token.tz)
	$(call compile_storage,fa12-token/storage/tzBTC_storage.mligo, tzBTC_fa12_token_storage.tz)
