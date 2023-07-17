.PHONY: test

LIGO_COMPILER_VERSION:=0.66.0
TEZOS_PROTOCOL:=mumbai
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

TEST_DIRECTORY:=test
STORAGE_DIRECTORY:=storage
TOKENS_DIRECTORY:=$(BATCHER_TEST_DIRECTORY)/tokens
FA12_DIRECTORY:=$(TOKENS_DIRECTORY)/fa12
FA12_STORAGE_DIRECTORY:=$(FA12_DIRECTORY)/storage
FA2_DIRECTORY:=$(TOKENS_DIRECTORY)/fa2
FA2_STORAGE_DIRECTORY:=$(FA2_DIRECTORY)/storage

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

define clean_mainnet_files
   rm -rf *mainnet.tz
endef

define clean_ghostnet_files
   rm -rf *ghostnet.tz
endef

clean:
	$(call clean_mainnet_files)
	$(call clean_ghostnet_files)
build-mainnet:
	$(call clean_mainnet_files)
	$(call compile_contract,batcher.mligo, batcher-mainnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/initial_storage_mainnet.mligo, batcher-storage-mainnet.tz)
build-ghostnet:
	$(call clean_ghostnet_files)
	$(call compile_contract,batcher.mligo, batcher-ghostnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/initial_storage_ghostnet.mligo, batcher-storage-ghostnet.tz)
build-tzBTC:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, tzBTC_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/tzBTC_storage.mligo, tzBTC_token_storage.tz)
build-USDT:
	$(call clean_files)
	$(call compile_contract,$(FA2_DIRECTORY)/main.mligo, USDT_token.tz)
	$(call compile_storage,$(FA2_STORAGE_DIRECTORY)/USDT_storage.mligo, USDT_token_storage.tz)
build-CTEZ:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, CTEZ_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/CTEZ_storage.mligo, CTEZ_token_storage.tz)
build-KUSD:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, KUSD_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/KUSD_storage.mligo, KUSD_token_storage.tz)
build-EURL:
	$(call clean_files)
	$(call compile_contract, $(FA2_DIRECTORY)/main.mligo, EURL_token.tz)
	$(call compile_storage, $(FA2_STORAGE_DIRECTORY)/EURL_storage.mligo, EURL_token_storage.tz)
build-fa12-tzBTC:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, tzBTC_fa12_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/tzBTC_storage.mligo, tzBTC_fa12_token_storage.tz)
test:
	$(call test_ligo,$(TEST_DIRECTORY)/test.mligo)
measure:
	$(call measure_contract,batcher.mligo)
install:
	$(call install_deps)
