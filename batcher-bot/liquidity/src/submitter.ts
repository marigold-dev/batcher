import {
  compose,
  OpKind,
  TezosToolkit,
  WalletContract,
} from "@taquito/taquito";
import { contract_details, order, token } from "./types";
import { tzip12 } from "@taquito/tzip12";
import { tzip16 } from "@taquito/tzip16";

export async function submit_fa2_deposit(
  user_address: string,
  batcher_contract: string,
  order: order,
  tezos: TezosToolkit,
  swap_params: any
) {
  let token_address = order.swap.from.token.address;
  let token_id: number = order.swap.from.token.token_id;
  if (token_address) {
    const fa2_add_operator_params = [
      {
        add_operator: {
          owner: user_address,
          operator: batcher_contract,
          token_id: token_id,
        },
      },
    ];

    const fa2_remove_operator_params = [
      {
        remove_operator: {
          owner: user_address,
          operator: batcher_contract,
          token_id: token_id,
        },
      },
    ];
    try {
      const batcherContract = await tezos.wallet.at(batcher_contract);
      const tokenfa2Contract: WalletContract = await tezos.wallet.at(
        token_address,
        compose(tzip12, tzip16)
      );
      const deposit_op = await tezos.wallet
        .batch([
          {
            kind: OpKind.TRANSACTION,
            ...tokenfa2Contract.methods
              .update_operators(fa2_add_operator_params)
              .toTransferParams(),
          },
          {
            kind: OpKind.TRANSACTION,
            ...batcherContract.methodsObject
              .deposit(swap_params)
              .toTransferParams(),
            to: batcher_contract,
            amount: 10000,
            mutez: true,
          },
          {
            kind: OpKind.TRANSACTION,
            ...tokenfa2Contract.methods
              .update_operators(fa2_remove_operator_params)
              .toTransferParams(),
          },
        ])
        .send();

      await deposit_op.confirmation();
    } catch (error: any) {
      console.error(error);
    }
  } else {
    throw new Error("No valid token address for fa12 token");
  }
}

export async function submit_fa12_deposit(
  batcher_contract: string,
  order: order,
  tezos: TezosToolkit,
  swap_params: any
) {
  let token_address = order.swap.from.token.address;
  let amount = order.swap.from.amount;
  if (token_address) {
    try {
      const batcherContract = await tezos.wallet.at(batcher_contract);
      const tokenfa12Contract: WalletContract = await tezos.wallet.at(
        token_address,
        compose(tzip12, tzip16)
      );
      const deposit_op = await tezos.wallet
        .batch([
          {
            kind: OpKind.TRANSACTION,
            ...tokenfa12Contract.methods
              .approve(batcher_contract, amount)
              .toTransferParams(),
          },
          {
            kind: OpKind.TRANSACTION,
            ...batcherContract.methodsObject
              .deposit(swap_params)
              .toTransferParams(),
            to: batcher_contract,
            amount: 10000,
            mutez: true,
          },
        ])
        .send();
      const confirmation = await deposit_op.confirmation();
    } catch (error: any) {
      console.error(error);
    }
  } else {
    throw new Error("No valid token address for fa12 token");
  }
}

export async function submit_deposit(
  contract_details: contract_details,
  order: order,
  tezos: TezosToolkit
) {
  let fromToken: token = order.swap.from.token;
  let user_address = contract_details.user_address;
  let batcher_address = contract_details.address;
  if (fromToken.standard) {
    const swap_params = {
      swap: order.swap,
      created_at: Math.floor(Date.now() / 1000),
      side: order.side,
      tolerance: order.tolerance,
    };

    if (fromToken.standard == "FA2 token") {
      return await submit_fa2_deposit(
        user_address,
        batcher_address,
        order,
        tezos,
        swap_params
      );
    } else {
      return await submit_fa12_deposit(
        batcher_address,
        order,
        tezos,
        swap_params
      );
    }
  }
}

export async function submit_redemption(
  batcher_contract: string,
  tezos: TezosToolkit
) {
  try {
    const batcher = await tezos.contract.at(batcher_contract);
    const redeemOp = batcher.methods.redeem();
    const op = await redeemOp.send();
    await op.confirmation();
    console.log("Successfully redeemed!");
  } catch (error: any) {
    console.error(error);
  }
}
