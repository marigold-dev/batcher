import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { message } from 'antd';
import { compose, OpKind, WalletContract } from '@taquito/taquito';
// import { ReactComponent as ExchangeDollarSvg } from '../../../img/exchange-dollar.svg';
import { getErrorMess, getFees, scaleAmountUp } from '../../utils/utils';
import { tzip12 } from '@taquito/tzip12';
import { tzip16 } from '@taquito/tzip16';
import { BatchWalletOperation } from '@taquito/taquito/dist/types/wallet/batch-operation';
import { useTezosToolkit } from '../../contexts/tezos-toolkit';
import { useSelector } from 'react-redux';
import {
  batcherStatusSelector,
  currentSwapSelector,
  priceStrategySelector,
  userAddressSelector,
  userBalancesSelector,
} from '../../src/reducers';
import { BatcherStatus, PriceStrategy } from '../../src/types';
import { useDispatch } from 'react-redux';
import { reverseSwap, updatePriceStrategy } from 'src/actions';
import * as Form from '@radix-ui/react-form';

const Exchange = () => {
  const userAddress = useSelector(userAddressSelector);
  const batcherStatus = useSelector(batcherStatusSelector);
  const priceStategy = useSelector(priceStrategySelector);
  const currentSwap = useSelector(currentSwapSelector);
  const userBalances = useSelector(userBalancesSelector);

  const { tezos } = useTezosToolkit();

  const { isReverse, swap } = currentSwap;

  const dispatch = useDispatch();

  const [amount, setAmount] = useState(0);
  const [fees, setFees] = useState(0);

  //TODO: rewrite with redux-loop
  useEffect(() => {
    getFees(process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || '').then(f =>
      setFees(f)
    );
  }, []);

  //TODO: rewrite error management
  if (!tezos)
    return (
      <div>
        <p className="text-xxl">
          {"There is an error with Tezos Tool Kit, can't swap !"}
        </p>
      </div>
    );

  const toTolerance = (isReverse: boolean, priceStategy: PriceStrategy) => {
    switch (priceStategy) {
      case PriceStrategy.EXACT:
        return 1;
      case PriceStrategy.BETTER:
        return isReverse ? 2 : 0;
      case PriceStrategy.WORSE:
        return isReverse ? 0 : 2;
    }
  };

  const depositToken = async () => {
    if (!userAddress) {
      return;
    }
    const batcherContractHash = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;
    if (!batcherContractHash) return;

    const tokenName = isReverse ? swap.to.name : swap.from.token.name;

    const selectedToken = isReverse ? swap.to : swap.from.token;

    const batcherContract = await tezos.wallet.at(batcherContractHash);

    if (!selectedToken.address) return; //TODO:improve this

    const tokenContract: WalletContract = await tezos.wallet.at(
      selectedToken.address,
      compose(tzip12, tzip16)
    );
    const tokenId = isReverse ? swap.to.token_id : swap.from.token.token_id;

    const scaled_amount = isReverse
      ? scaleAmountUp(amount, swap.to.decimals)
      : scaleAmountUp(amount, swap.from.token.decimals);

    const tolerance = toTolerance(isReverse, priceStategy);

    // This is for fa2 token standard. I.e, USDT token
    const fa2_add_operator_params = [
      {
        add_operator: {
          owner: userAddress,
          operator: batcherContractHash,
          token_id: tokenId,
        },
      },
    ];

    const fa2_remove_operator_params = [
      {
        remove_operator: {
          owner: userAddress,
          operator: batcherContractHash,
          token_id: tokenId,
        },
      },
    ];

    try {
      let order_batcher_op: BatchWalletOperation | undefined = undefined;

      const swap_params = {
        swap: isReverse
          ? {
              from: {
                token: {
                  ...currentSwap.swap.to,
                },
                amount: scaleAmountUp(amount, currentSwap.swap.to.decimals),
              },
              to: {
                ...currentSwap.swap.from.token,
              },
            }
          : {
              from: {
                token: { ...currentSwap.swap.from.token },
                amount: scaleAmountUp(
                  amount,
                  currentSwap.swap.from.token.decimals
                ),
              },
              to: {
                ...currentSwap.swap.to,
              },
            },
        created_at: new Date(),
        side: isReverse ? 0 : 1,
        tolerance,
      };

      if (selectedToken.standard === 'FA1.2 token') {
        if (!swap.from.token.address) return; //TODO: improve this
        const tokenfa12Contract = await tezos?.wallet.at(
          swap.from.token.address,
          compose(tzip12, tzip16)
        );

        order_batcher_op = await tezos.wallet
          .batch([
            {
              kind: OpKind.TRANSACTION,
              ...tokenfa12Contract.methods
                .approve(batcherContractHash, scaled_amount)
                .toTransferParams(),
            },
            {
              kind: OpKind.TRANSACTION,
              ...batcherContract.methodsObject
                .deposit(swap_params)
                .toTransferParams(),
              to: batcherContractHash,
              amount: fees,
              mutez: true,
            },
          ])
          .send();
      }

      if (selectedToken.standard === 'FA2 token') {
        order_batcher_op = await tezos?.wallet
          .batch([
            {
              kind: OpKind.TRANSACTION,
              ...tokenContract.methods
                .update_operators(fa2_add_operator_params)
                .toTransferParams(),
            },
            {
              kind: OpKind.TRANSACTION,
              ...batcherContract.methodsObject
                .deposit(swap_params)
                .toTransferParams(),
              to: batcherContractHash,
              amount: fees,
              mutez: true,
            },
            {
              kind: OpKind.TRANSACTION,
              ...tokenContract.methods
                .update_operators(fa2_remove_operator_params)
                .toTransferParams(),
            },
          ])
          .send();
      }

      if (!order_batcher_op) {
        console.error('Order Batcher Operation is not defined...');
        throw new Error('Order Batcher Operation is not defined...');
      }

      const confirm = await order_batcher_op?.confirmation();

      confirm?.completed ? console.log('Successfully deposited !!!!!!') : null;

      if (!confirm.completed) {
        console.error(confirm);
        throw new Error(
          `Failed to deposit ${
            isReverse ? swap.to.name : swap.from.token.name
          } token.`
        );
      } else {
        console.info(`Successfully deposited ${tokenName}`);
        //   form.resetFields();
        //   message.success('Successfully deposited ' + tokenName);
      }
    } catch (error) {
      console.log('deposit error', error);
      const converted_error_message = getErrorMess(error);
      message.error(converted_error_message);
      message.loading('Attempting to place swap order for ' + tokenName, 0);
    }
  };

  return (
    <div className="flex flex-col items-center font-custom">
      <div className="max-w-fit p-5 flex flex-col items-center border-2 border-solid">
        <Form.Root
          className="flex flex-col items-center"
          onSubmit={event => {
            event.preventDefault();
            depositToken();
          }}>
          <Form.Field className="grid mb-[10px]" name="amount">
            <div className="flex items-baseline justify-between">
              <Form.Label className="text-xl font-medium leading-[35px] text-white">
                {`From ${
                  isReverse
                    ? currentSwap.swap.to.name
                    : currentSwap.swap.from.token.name
                }`}
              </Form.Label>
            </div>

            <Form.Control asChild>
              <input
                className="box-border w-full bg-white shadow-black inline-flex h-[35px] items-center justify-center rounded-[4px] px-[10px] text-[15px] leading-none text-black outline-none"
                onChange={event => setAmount(parseFloat(event.target.value))}
                type="number"
                min={0}
                required
              />
            </Form.Control>
            <Form.Message
              className="text-[13px] text-[red] opacity-[0.8]"
              match={'valueMissing'}>
              Please input your amount
            </Form.Message>
            <Form.Message
              className="text-[13px] text-[red] opacity-[0.8]"
              match={'badInput'}>
              Invalid input.
            </Form.Message>
            <Form.Message
              className="text-[13px] text-[red] opacity-[0.8]"
              match={value => {
                return (
                  (isReverse &&
                    Number.parseFloat(value) >
                      userBalances[swap.to.name.toUpperCase()]) ||
                  (!isReverse &&
                    Number.parseFloat(value) >
                      userBalances[swap.from.token.name.toUpperCase()])
                );
              }}>
              Greater than the balance.
            </Form.Message>
          </Form.Field>

          <p className="p-5">Select the price you want to sell</p>
          <div className="flex">
            <button
              type="button"
              onClick={() => dispatch(updatePriceStrategy(PriceStrategy.WORSE))}
              className={
                priceStategy === PriceStrategy.WORSE
                  ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                  : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
              }>
              Worse price / Better fill
            </button>
            <button
              type="button"
              className={
                priceStategy === PriceStrategy.EXACT
                  ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                  : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
              }
              onClick={() =>
                dispatch(updatePriceStrategy(PriceStrategy.EXACT))
              }>
              Oracle Price
            </button>
            <button
              type="button"
              className={
                priceStategy === PriceStrategy.BETTER
                  ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                  : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
              }
              onClick={() =>
                dispatch(updatePriceStrategy(PriceStrategy.BETTER))
              }>
              Better Price / Worse Fill
            </button>
          </div>

          <div className="flex flex-row p-10 text-[#1C1D22]">
            <SwapOutlined
              className="text-[#ff4d4f]"
              onClick={() => dispatch(reverseSwap())}
              size={42}
              rotate={90}
            />
          </div>
          <div className="">
            <p className="p-4">
              {`To ${
                isReverse
                  ? currentSwap.swap.from.token.name
                  : currentSwap.swap.to.name
              }`}
            </p>
          </div>

          <Form.Submit asChild>
            <button
              disabled={!userAddress || batcherStatus !== BatcherStatus.OPEN}
              className="box-border text-black inline-flex h-[35px] items-center justify-center rounded-[4px] bg-white px-[15px] font-medium leading-none mt-[10px] text-xl">
              Swap
            </button>
          </Form.Submit>
        </Form.Root>
      </div>
    </div>
  );
};

export default Exchange;
