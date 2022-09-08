.PHONY: test

LIGO_COMPILER_VERSION:=0.50.0
TEZOS_PROTOCOL:=jakarta
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

define test_ligo
  $(LIGO_DOCKER) run test $(1) --protocol $(TEZOS_PROTOCOL)
endef

test:
	$(call test_ligo,batcher/test/test_batcher_sc.mligo)
	$(call test_ligo,batcher/test/test_orders.mligo)

test-math: 
	$(call test_ligo,batcher/test/test_math.mligo)

test-view: 
	$(call test_ligo,batcher/test/test_on_chain_view.mligo)

