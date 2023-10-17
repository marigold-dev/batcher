.PHONY: test

LIGO_COMPILER_VERSION:=0.70.0
TEZOS_PROTOCOL:=mumbai
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

TEST_DIRECTORY:=test
STORAGE_DIRECTORY:=storage
MICHELSON_DIRECTORY:=michelson
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

define build_vault
	$(call compile_contract,vault.mligo, $(MICHELSON_DIRECTORY)/'$(1)-vault-$(2).tz')
	$(call compile_storage,$(STORAGE_DIRECTORY)/$(1)_vault_storage_$(2).mligo, $(MICHELSON_DIRECTORY)/$(1)-vault-storage-$(2).tz)
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
	$(call compile_contract,batcher.mligo, $(MICHELSON_DIRECTORY)/batcher-mainnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/initial_storage_mainnet.mligo, $(MICHELSON_DIRECTORY)/batcher-storage-mainnet.tz)
build-ghostnet:
	$(call clean_ghostnet_files)
	$(call compile_contract,batcher.mligo, $(MICHELSON_DIRECTORY)/batcher-ghostnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/initial_storage_ghostnet.mligo, $(MICHELSON_DIRECTORY)/batcher-storage-ghostnet.tz)
build-mm-mainnet:
	$(call compile_contract,marketmaker.mligo, $(MICHELSON_DIRECTORY)/marketmaker-mainnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/marketmaker_storage_mainnet.mligo, $(MICHELSON_DIRECTORY)/marketmaker-storage-mainnet.tz)
build-mm-ghostnet:
	$(call compile_contract,marketmaker.mligo, $(MICHELSON_DIRECTORY)/marketmaker-ghostnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/marketmaker_storage_ghostnet.mligo, $(MICHELSON_DIRECTORY)/marketmaker-storage-ghostnet.tz)
build-tm-mainnet:
	$(call compile_contract,tokenmanager.mligo, $(MICHELSON_DIRECTORY)/tokenmanager-mainnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/tokenmanager_storage_mainnet.mligo, $(MICHELSON_DIRECTORY)/tokenmanager-storage-mainnet.tz)
build-tm-ghostnet:
	$(call compile_contract,tokenmanager.mligo, $(MICHELSON_DIRECTORY)/tokenmanager-ghostnet.tz)
	$(call compile_storage,$(STORAGE_DIRECTORY)/tokenmanager_storage_ghostnet.mligo, $(MICHELSON_DIRECTORY)/tokenmanager-storage-ghostnet.tz)
build-tzbtc-vault-mainnet:
	$(call build_vault,tzbtc,mainnet)
build-tzbtc-vault-ghostnet:
	$(call build_vault,tzbtc,ghostnet)
build-btctz-vault-mainnet:
	$(call build_vault,btctz,mainnet)
build-btctz-vault-ghostnet:
	$(call build_vault,btctz,ghostnet)
build-eurl-vault-mainnet:
	$(call build_vault,eurl,mainnet)
build-eurl-vault-ghostnet:
	$(call build_vault,eurl,ghostnet)
build-usdt-vault-mainnet:
	$(call build_vault,usdt,mainnet)
build-usdt-vault-ghostnet:
	$(call build_vault,usdt,ghostnet)
build-usdtz-vault-mainnet:
	$(call build_vault,usdtz,mainnet)
build-usdtz-vault-ghostnet:
	$(call build_vault,usdtz,ghostnet)
build-tzBTC:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/tzBTC_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/tzBTC_storage.mligo, $(MICHELSON_DIRECTORY)/tzBTC_token_storage.tz)
build-USDT:
	$(call clean_files)
	$(call compile_contract,$(FA2_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/USDT_token.tz)
	$(call compile_storage,$(FA2_STORAGE_DIRECTORY)/USDT_storage.mligo, $(MICHELSON_DIRECTORY)/USDT_token_storage.tz)
build-CTEZ:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/CTEZ_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/CTEZ_storage.mligo, $(MICHELSON_DIRECTORY)/CTEZ_token_storage.tz)
build-KUSD:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/KUSD_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/KUSD_storage.mligo, $(MICHELSON_DIRECTORY)/KUSD_token_storage.tz)
build-EURL:
	$(call clean_files)
	$(call compile_contract, $(FA2_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/EURL_token.tz)
	$(call compile_storage, $(FA2_STORAGE_DIRECTORY)/EURL_storage.mligo, $(MICHELSON_DIRECTORY)/EURL_token_storage.tz)
build-fa12-tzBTC:
	$(call clean_files)
	$(call compile_contract,$(FA12_DIRECTORY)/main.mligo, $(MICHELSON_DIRECTORY)/tzBTC_fa12_token.tz)
	$(call compile_storage,$(FA12_STORAGE_DIRECTORY)/tzBTC_storage.mligo, $(MICHELSON_DIRECTORY)/tzBTC_fa12_token_storage.tz)
test-mm:
	$(call test_ligo,$(TEST_DIRECTORY)/test-market-maker.mligo)
test-tm:
	$(call test_ligo,$(TEST_DIRECTORY)/test-tokenmanager.mligo)
test-batcher:
	$(call test_ligo,$(TEST_DIRECTORY)/test-batcher.mligo)
test-all:
	$(call test_ligo,$(TEST_DIRECTORY)/test-batcher.mligo)
	$(call test_ligo,$(TEST_DIRECTORY)/test-market-maker.mligo)
measure:
	$(call measure_contract,batcher.mligo)
measure-mm:
	$(call measure_contract,marketmaker.mligo)
measure-tm:
	$(call measure_contract,tokenmanager.mligo)
install:
	$(call install_deps)

