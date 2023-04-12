.PHONY: test

LIGO_COMPILER_VERSION:=0.63.2
TEZOS_PROTOCOL:=lima
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

define test_ligo
  $(LIGO_DOCKER) run test $(1) 
endef

define compile_contract
    $(LIGO_DOCKER) compile contract $(1) -e  main -s cameligo -o $(2) --protocol $(TEZOS_PROTOCOL)
endef

define compile_storage
    $(LIGO_DOCKER) compile expression cameligo -p $(TEZOS_PROTOCOL) --michelson-format text --werror --init-file $(1) 'f()' > $(2)
endef

define measure_contract
    $(LIGO_DOCKER) info measure-contract -p $(TEZOS_PROTOCOL)  $(1)
endef

define install_deps
    $(LIGO_DOCKER) install
endef

define clean_files
   rm -rf *.tz
   rm -rf batcher/*.tz
endef

clean:
	$(call clean_files)
build-ghostnet:
	$(call clean_files)
	$(call compile_contract,batcher.mligo, batcher-mainnet.tz)
	$(call compile_storage,storage/initial_storage_mainnet.mligo, batcher-storage-mainnet.tz)
build-ghostnet:
	$(call clean_files)
	$(call compile_contract,batcher.mligo, batcher-ghostnet.tz)
	$(call compile_storage,storage/initial_storage_ghostnet.mligo, batcher-storage-ghostnet.tz)
build-tzBTC:
	$(call clean_files)
	$(call compile_contract,tokens/fa12/main.mligo, tzBTC_token.tz)
	$(call compile_storage,tokens/fa12/storage/tzBTC_storage.mligo, tzBTC_token_storage.tz)
build-USDT:
	$(call clean_files)
	$(call compile_contract,tokens/fa2/main.mligo, USDT_token.tz)
	$(call compile_storage,tokens/fa2/storage/USDT_storage.mligo, USDT_token_storage.tz)
build-CTEZ:
	$(call clean_files)
	$(call compile_contract,tokens/fa12/main.mligo, CTEZ_token.tz)
	$(call compile_storage,tokens/fa12/storage/CTEZ_storage.mligo, CTEZ_token_storage.tz)
build-KUSD:
	$(call clean_files)
	$(call compile_contract,tokens/fa12/main.mligo, KUSD_token.tz)
	$(call compile_storage,tokens/fa12/storage/KUSD_storage.mligo, KUSD_token_storage.tz)
build-EURL:
	$(call clean_files)
	$(call compile_contract,tokens/fa2/main.mligo, EURL_token.tz)
	$(call compile_storage,tokens/fa2/storage/EURL_storage.mligo, EURL_token_storage.tz)
build-fa12-tzBTC:
	$(call clean_files)
	$(call compile_contract,tokens/fa12/main.mligo, tzBTC_fa12_token.tz)
	$(call compile_storage,tokens/fa12/storage/tzBTC_storage.mligo, tzBTC_fa12_token_storage.tz)
test:
	$(call test_ligo,test/test_batcher_sc.mligo)
measure:
	$(call measure_contract,batcher.mligo)
install:
	$(call install_deps)