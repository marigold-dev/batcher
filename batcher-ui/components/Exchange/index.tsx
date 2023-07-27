import React, { useState, useEffect, useContext } from 'react';
import { SwapOutlined, SettingOutlined } from '@ant-design/icons';
import { message, Form } from "antd";
import { compose, OpKind, WalletContract } from "@taquito/taquito";
import { ExchangeProps, PriceType } from '../../extra_utils/types';
// import { ReactComponent as ExchangeDollarSvg } from '../../../img/exchange-dollar.svg';
import { getErrorMess, scaleAmountUp } from '../../extra_utils/utils';
import { tzip12 } from '@taquito/tzip12';
import { tzip16 } from '@taquito/tzip16';
import { BatchWalletOperation } from '@taquito/taquito/dist/types/wallet/batch-operation';
import { TezosToolkitContext } from '../../contexts/tezos-toolkit';
import { useSelector } from 'react-redux';
import {
  batcherStatusSelector,
  priceStrategySelector,
  userAddressSelector,
} from '../../src/reducers';
// import { isNone } from 'fp-ts/lib/Option';
import { BatcherStatus, PriceStrategy } from '../../src/types';
import { useDispatch } from 'react-redux';
import { reverseSwap, updatePriceStrategy } from 'src/actions';

const Exchange: React.FC<ExchangeProps> = ({
  // buyBalance,
  // sellBalance,
  inversion,
  // setInversion,
  toggleInversion,
  fee_in_mutez,
  buyToken,
  sellToken,
  showDrawer,
  // updateAll,
  // setUpdateAll,
  status,
}: ExchangeProps) => {
  const userAddress = useSelector(userAddressSelector);
  const batcherStatus = useSelector(batcherStatusSelector);
  const priceStategy = useSelector(priceStrategySelector);

  const dispatch = useDispatch();

  const [side, setSide] = useState(0);
  const [amount, setAmount] = useState(0);

  const [form] = Form.useForm();

  // const triggerUpdate = () => {
  //   setTimeout(function () {
  //     const u = !updateAll;
  //     setUpdateAll(u);
  //   }, 5000);
  // };

  // const inverseTokenType = () => {
  //   // setInversion(!inversion);
  //   toggleInversion();
  //   const s = inversion ? 0 : 1;
  //   setSide(s);
  // };

  const depositToken = async () => {
    // if (isNone(userAddress)) {
    if (!userAddress) {
      return;
    }
    const batcherContractHash = process.env.REACT_APP_BATCHER_CONTRACT_HASH;
    if (!batcherContractHash) return;

    const tokenName = inversion ? buyToken.name : sellToken.name;
    const selectedToken = inversion ? buyToken : sellToken;
    const batcherContract = await connection.wallet.at(batcherContractHash);

    if (!selectedToken.address) return; //TODO:improve this

    const tokenContract: WalletContract = await connection.wallet.at(
      selectedToken.address,
      compose(tzip12, tzip16)
    );
    const tokenId = inversion ? buyToken.token_id : sellToken.token_id;

    const scaled_amount = inversion
      ? scaleAmountUp(amount, buyToken.decimals)
      : scaleAmountUp(amount, sellToken.decimals);

    const selected_side = inversion ? 0 : 1;
    let tolerance = 0;

    if (selected_side == 0) {
      if (price === PriceType.WORSE) {
        tolerance = 0;
      } else if (price === PriceType.EXACT) {
        tolerance = 1;
      } else {
        tolerance = 2;
      }
    } else {
      if (price === PriceType.WORSE) {
        tolerance = 2;
      } else if (price === PriceType.EXACT) {
        tolerance = 1;
      } else {
        tolerance = 0;
      }
    }

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

    // let loading = function () {
    //   return undefined;
    // };

    try {
      let order_batcher_op: BatchWalletOperation | undefined = undefined;

      console.log('operations-token', selectedToken);
      console.log('operations-side', side);
      console.log('operations-fee-in-mutez', fee_in_mutez);
      console.log('operations-scaled-amount', fee_in_mutez);

      const swap_params = {
        swap: {
          from: {
            token: {
              token_id: inversion ? buyToken.token_id : sellToken.token_id,
              name: inversion ? buyToken.name : sellToken.name,
              address: inversion ? buyToken.address : sellToken.address,
              decimals: inversion ? buyToken.decimals : sellToken.decimals,
              standard: inversion ? buyToken.standard : sellToken.standard,
            },
            amount: scaled_amount,
          },
          to: {
            token_id: inversion ? sellToken.token_id : buyToken.token_id,
            name: inversion ? sellToken.name : buyToken.name,
            address: inversion ? sellToken.address : buyToken.address,
            decimals: inversion ? sellToken.decimals : buyToken.decimals,
            standard: inversion ? sellToken.standard : buyToken.standard,
          },
        },
        created_at: new Date(),
        side: selected_side,
        tolerance: tolerance,
      };

      console.log('test');

      if (selectedToken.standard === 'FA1.2 token') {
        console.log('inversion', inversion);
        console.log('buy', buyToken);
        console.log('sell', sellToken);

        if (!buyToken.address) return; //TODO: improve this

        const tokenfa12Contract: WalletContract = await connection.wallet.at(
          buyToken.address,
          compose(tzip12, tzip16)
        );
        console.log('methods', tokenfa12Contract.methods);
        order_batcher_op = await connection.wallet
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
              amount: fee_in_mutez,
              mutez: true,
            },
          ])
          .send();
      }

      if (selectedToken.standard === 'FA2 token') {
        order_batcher_op = await connection.wallet
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
              amount: fee_in_mutez,
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

      const loading = () =>
        message.loading('Attempting to place swap order for ' + tokenName, 0);

      if (!order_batcher_op) {
        console.error('Order Batcher Operation is not defined...');
        throw new Error('Order Batcher Operation is not defined...');
      }
      const confirm = await order_batcher_op.confirmation();

      if (!confirm.completed) {
        console.error(confirm);
        message.error('Failed to deposit ' + tokenName);
        throw new Error(
          'Failed to deposit ' +
            (inversion ? buyToken.name : sellToken.name) +
            ' token'
        );
      } else {
        loading();
        form.resetFields();
        message.success('Successfully deposited ' + tokenName);
        triggerUpdate();
      }
    } catch (error) {
      console.log('deposit error', error);
      const converted_error_message = getErrorMess(error);
      message.error(converted_error_message);
      message.loading('Attempting to place swap order for ' + tokenName, 0);
      form.resetFields();
    }
  };

  return (
    <div className="flex flex-col items-center font-custom">
      {/* <Form onFinish={depositToken} form={form} className="bg-[green]"> */}
      <div className="max-w-fit p-5 flex flex-col items-center border-2 border-solid">
        <div className="p-5 gap-5 flex flex-row">
          <label htmlFor="amount">
            <p className="text-xl p-2">
              From {inversion ? buyToken.name : sellToken.name}
            </p>
          </label>
          <input
            type="text"
            id="amount"
            name="Amount"
            disabled={!userAddress}
            required
          />

          {/* <Form.Item
              className=""
              label={
                <p className="text-xl p-16">
                  From {inversion ? buyToken.name : sellToken.name}
                </p>
              }
              name="amount"
              rules={[
                { required: true, message: "Please input your amount" },
                {
                  pattern: new RegExp(/^[+-]?([0-9]*[.])?[0-9]+$/),
                  message: "Invalid number",
                },
                () => ({
                  validator(_, value) {
                    if (inversion && Number.parseFloat(value) > buyBalance) {
                      return Promise.reject("Greater than the balance");
                    } else if (
                      !inversion &&
                      Number.parseFloat(value) > sellBalance
                    ) {
                      return Promise.reject("Greater than the balance");
                    }
                    return Promise.resolve();
                  },
                }),
              ]}
            >
              <Input
                className="batcher-token"
                placeholder="Amount"
                disabled={!userAddress}
                onChange={(e) => {
                  const regrex = /^[+-]?([0-9]*[.])?[0-9]+$/;
                  if (regrex.test(e.target.value)) {
                    setAmount(Number.parseFloat(e.target.value));
                  }
                }}
              />
            </Form.Item> */}
        </div>
        <p className="p-5">Select the price you want to sell</p>
        <div className="flex">
          <button
            onClick={() => dispatch(updatePriceStrategy(PriceStrategy.WORSE))}
            className={
              priceStategy === PriceStrategy.WORSE
                ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
            }>
            Worse price / Better fill
          </button>
          <button
            className={
              priceStategy === PriceStrategy.EXACT
                ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
            }
            onClick={() => dispatch(updatePriceStrategy(PriceStrategy.EXACT))}>
            Oracle Price
          </button>
          <button
            className={
              priceStategy === PriceStrategy.BETTER
                ? 'p-5 text-l border-2 border-[#7B7B7E] border-solid bg-[white] text-[#1C1D22]'
                : 'p-5 text-l border-2 border-[#7B7B7E] border-solid'
            }
            onClick={() => dispatch(updatePriceStrategy(PriceStrategy.BETTER))}>
            Better Price / Worse Fill
          </button>
        </div>
      </div>
      <div className="flex flex-row p-10 text-[#1C1D22]">
        <SwapOutlined
          className="text-[#ff4d4f]"
          onClick={() => dispatch(reverseSwap())}
          size={42}
          rotate={90}
        />
        <div onClick={showDrawer}>
          <SettingOutlined className="text-[#ff4d4f]" />
        </div>
      </div>
      <div className="">
        <p className="p-4">To {inversion ? sellToken.name : buyToken.name}</p>
      </div>

      {/* Means batch is OPEN and user has connect his wallet */}
      {userAddress && batcherStatus === BatcherStatus.STARTED ? (
        <div className="text-center">
          <button
            className="text-xs"
            type="submit"
            onClick={() => depositToken()}>
            Try to swap
          </button>
        </div>
      ) : null}
      {/* </Form> */}
    </div>
  );
};

export default Exchange;
