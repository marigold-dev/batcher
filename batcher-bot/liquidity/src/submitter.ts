import { TezosToolkit } from "@taquito/taquito";
import { order } from "./types";
import { loadKey } from "./wallet";

const Tezos = new TezosToolkit('https://ghostnet.tezos.marigold.dev');

export function init_toolkit() {
  loadKey(Tezos);
}

async function submit_async (order: order) {
  const token_address = order.swap.from.token.address;
  if (token_address.isNone())
    throw "Token need an address";
  const tzBTC = await Tezos.contract.at(token_address.get());

  // FIXME: get this address from somewhere else
  const batcher = await Tezos.contract.at('KT1VbeN9etQe5c2b6EAFfCZVaSTpiieHj5u1')

  // Check that we don't already have an allowance
  const fa12_storage = await tzBTC.storage();
  try {
    const allowance = await fa12_storage["allowances"].get({
      "owner": await Tezos.signer.publicKeyHash(),
      "spender": await batcher.address
    });
    if (allowance > 0) {
      console.log("Allowance is not 0, resetting");
      const fa12_allowance_reset = tzBTC.methodsObject.approve({
        spender: await batcher.address,
        value: 0
      });
      const opReset = await fa12_allowance_reset.send();
      await opReset.confirmation();
    }
  }
  catch (e) {
    console.error(e);
  }

  // Allowing a deposit
  // TODO: same transaction as deposit
  const fa12_allowance = tzBTC.methodsObject.approve({
    spender: await batcher.address,
    value: order.swap.from.amount
  });
  const op = await fa12_allowance.send();
  await op.confirmation();
  // TODO: test if a batch is open
  try {
    const deposit = batcher.methodsObject.deposit({
      swap: order.swap,
      created_at: Math.floor(Date.now() / 1000),
      side: order.side,
      tolerance: order.tolerance,
    });
    const op2 = await deposit.send({ amount: 0.01 });
    await op2.confirmation();
  }
  catch (e) {
    console.log("***");
    console.log(e);   // FIXME: this happens when no batch is open
  }
}

export async function submit_deposit (order: order) {
  return await submit_async(order);
};

async function redeem_async() {
  const batcher = await Tezos.contract.at('KT1VbeN9etQe5c2b6EAFfCZVaSTpiieHj5u1')
  const redeemOp = batcher.methods.redeem();
  const op = await redeemOp.send();
  await op.confirmation();
  console.log("Successfully redeemed!");
}

export async function submit_redemption () {
  return await redeem_async();
};
