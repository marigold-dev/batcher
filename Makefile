.PHONY: test

LIGO_COMPILER_VERSION:=0.50.0
TEZOS_PROTOCOL:=jakarta
LIGO_DOCKER := docker run --rm  -v $(PWD):$(PWD) -w $(PWD) ligolang/ligo:$(LIGO_COMPILER_VERSION)

define test_ligo
  $(LIGO_DOCKER) run test $(1) --protocol $(TEZOS_PROTOCOL)
endef

test:
<<<<<<< HEAD
<<<<<<< HEAD
	$(call test_ligo,batcher/test/test_batcher_sc.mligo)
	$(call test_ligo,batcher/test/test_orders.mligo)

test-math: 
	$(call test_ligo,batcher/test/test_math.mligo)

=======
	$(call test_ligo,batcher/test/test_orders.mligo)
	$(call test_ligo,batcher/test/util.mligo)
>>>>>>> 260f47c (rebase)
=======
	$(call test_ligo,batcher/test/test_orders.mligo)
	$(call test_ligo,batcher/test/util.mligo)
>>>>>>> 754bbce (add a start of an implementation about the order matching, with pushing order function, fill order, and a simple test about push order)
