import React, { useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import * as Form from '@radix-ui/react-form';
import { MVault, VaultToken } from '../types';
import { getFees, scaleAmountUp } from '../utils/utils';
import { tzip12 } from '@taquito/tzip12';
import { tzip16 } from '@taquito/tzip16';
import { compose, OpKind, WalletContract } from '@taquito/taquito';
import SelectMMPair from './SelectMMPair';
import { getMVault } from 'src/utils/utils';
import { useSelector } from 'react-redux';
import { fetchUserBalances } from '../actions';
import {
  userBalancesSelector,
  userAddressSelector,
  getCurrentGlobalVaultSelector,
  getCurrentUserVaultSelector,
} from '../reducers';
import { useTezosToolkit } from '../contexts/tezos-toolkit';
import { BatchWalletOperation } from '@taquito/taquito/dist/types/wallet/batch-operation';
import { useDispatch } from 'react-redux';

// interface MMVaultProps {
//   vaults: Map<string, MVault>;
//   current_vault: MVault;
// }
const MMVaultComponent = () => {
  const dispatch = useDispatch();
  const marketMakerAddress = process.env.NEXT_PUBLIC_MARKETMAKER_CONTRACT_HASH;
  const userAddress = useSelector(userAddressSelector);
  const { tezos } = useTezosToolkit();
  const userBalances = useSelector(userBalancesSelector);
  const [amountInput, setAmount] = useState<string>('0');

  const currentGlobalVault = useSelector(getCurrentGlobalVaultSelector);
  const currentUserVault = useSelector(getCurrentUserVaultSelector);

  const showTokenAmount = ({ vaultToken }: { vaultToken: VaultToken }) => (
    <div className="p-3">
      <p className="text-lg text-center">
        {vaultToken?.name} : {vaultToken?.amount}
      </p>
    </div>
  );
  const showForeignAssets = (assets: Map<string, VaultToken>) => (
    <div>
      {assets.size > 0 ? (
        Object.values(assets).map(a => showTokenAmount({ vaultToken: a }))
      ) : (
        <div></div>
      )}
    </div>
  );

  const addLiquidity = async ({
    tokenName,
    tokenAmount,
  }: {
    tokenName: string;
    tokenAmount: number;
  }) => {
    console.log(tokenName);
    console.log(tokenAmount);
    if (!userAddress) {
      console.info('No user address');
      return;
    }
    if (!marketMakerAddress) {
      console.info('No contract address');
      return;
    }

    const mmContract = await tezos?.wallet.at(marketMakerAddress);

    console.info(current_vault);

    if (!current_vault.global.native.address) {
      console.info('No token address');
      return; //TODO:improve this
    }
    const token = current_vault.global.native;
    console.info(token);
    const tokenContract: WalletContract = await tezos.wallet.at(
      token.address,
      compose(tzip12, tzip16)
    );

    const scaled_amount = scaleAmountUp(tokenAmount, token.decimals);

    // This is for fa2 token standard. I.e, USDT token
    const fa2_add_operator_params = [
      {
        add_operator: {
          owner: userAddress,
          operator: marketMakerAddress,
          token_id: token.id,
        },
      },
    ];

    const fa2_remove_operator_params = [
      {
        remove_operator: {
          owner: userAddress,
          operator: marketMakerAddress,
          token_id: token.id,
        },
      },
    ];

    try {
      let liq_op: BatchWalletOperation | undefined = undefined;
      const liq_params = {
        token: {
          token_id: token.id,
          name: token.name,
          address: token.address,
          decimals: token.decimals,
          standard: token.standard,
        },
        amount: scaled_amount,
      };

      if (token.standard === 'FA1.2 token') {
        const tokenfa12Contract = await tezos.wallet.at(
          token.address,
          compose(tzip12, tzip16)
        );

        liq_op = await tezos?.wallet
          .batch([
            {
              kind: OpKind.TRANSACTION,
              ...tokenfa12Contract.methods
                .approve(marketMakerAddress, scaled_amount)
                .toTransferParams(),
            },
            {
              kind: OpKind.TRANSACTION,
              ...mmContract?.methodsObject
                .addLiquidity(liq_params)
                .toTransferParams(),
              to: marketMakerAddress,
              amount: 0,
              mutez: true,
            },
          ])
          .send();
      }

      if (token.standard === 'FA2 token') {
        liq_op = await tezos?.wallet
          .batch([
            {
              kind: OpKind.TRANSACTION,
              ...tokenContract.methods
                .update_operators(fa2_add_operator_params)
                .toTransferParams(),
            },
            {
              kind: OpKind.TRANSACTION,
              ...mmContract?.methodsObject
                .addLiquidity(liq_params)
                .toTransferParams(),
              to: marketMakerAddress,
              amount: 0,
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

      if (!liq_op) {
        console.error('Liquidity Operation is not defined...');
        throw new Error('Liquidity Operation is not defined...');
      }

      const confirm = await liq_op?.confirmation();

      confirm?.completed
        ? console.log('Successfully added liquidity !!!!!!')
        : null;

      if (!confirm.completed) {
        console.error(confirm);
        throw new Error(`Failed to add liquidity ${token.name} token.`);
      } else {
        console.info(`Successfully added liquidity ${tokenName}`);

        dispatch(fetchUserBalances());
        setAmount('0');
      }
    } catch (error) {
      console.log('liquidity error', error);
    }
  };

  const claimRewards = async ({ tokenName }: { tokenName: string }) => {
    console.log('claiming');
    try {
      if (!tezos || !marketMakerAddress) {
        throw new Error('Failed to initialize communication with contract.');
      }
      const contractWallet = await tezos.wallet.at(marketMakerAddress);

      let claimTransaction = await contractWallet.methods
        .claim(tokenName)
        .send();

      if (claimTransaction) {
        const confirm = await claimTransaction.confirmation();
        if (!confirm.completed) {
          console.error('Failed to claimed rewards' + confirm);
        } else {
          console.info('Successfully claimed rewards');
        }
      } else {
        throw new Error('Failed to claimed rewards');
      }
    } catch (error: any) {
      console.error('Unable to claimed rewards' + error);
    }
  };

  const showClaimRewards = ({ vaultToken }: { vaultToken: VaultToken }) => {
    return (
      <div className="flex flex-col grow my-2">
        <Form.Root
          className="flex flex-col items-strech"
          onSubmit={event => {
            event.preventDefault();
            claimRewards({
              tokenName: vaultToken.name,
            });
          }}>
          <Form.Submit asChild>
            <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
              Claim
            </button>
          </Form.Submit>
        </Form.Root>
      </div>
    );
  };

  const removeLiquidity = async ({ tokenName }: { tokenName: string }) => {
    console.log('removing');
    try {
      if (!tezos || !marketMakerAddress) {
        throw new Error('Failed to initialize communication with contract.');
      }
      const contractWallet = await tezos.wallet.at(marketMakerAddress);

      let claimTransaction = await contractWallet.methods
        .removeLiquidity(tokenName)
        .send();

      if (claimTransaction) {
        const confirm = await claimTransaction.confirmation();
        if (!confirm.completed) {
          console.error('Failed to remove liquidity' + confirm);
        } else {
          console.info('Successfully removed liquidity ');
        }
      } else {
        throw new Error('Failed to removed liquidity');
      }
    } catch (error: any) {
      console.error('Unable to remove liquidity' + error);
    }
  };

  const showRemoveLiquidity = ({ vaultToken }: { vaultToken: VaultToken }) => {
    return (
      <div className="flex flex-col grow my-2">
        <Form.Root
          className="flex flex-col items-strech"
          onSubmit={event => {
            event.preventDefault();
            removeLiquidity({
              tokenName: vaultToken.name,
            });
          }}>
          <Form.Submit asChild>
            <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
              Remove
            </button>
          </Form.Submit>
        </Form.Root>
      </div>
    );
  };
  const showAddLiquidity = ({
    vaultToken,
    userBalances,
  }: {
    vaultToken: VaultToken;
    userBalances: Record<string, number>;
  }) => {
    return (
      <div className="flex flex-col grow my-2">
        <Form.Root
          className="flex flex-col items-strech"
          onSubmit={event => {
            event.preventDefault();
            addLiquidity({
              tokenName: vaultToken.name,
              tokenAmount: parseInt(amountInput),
            });
          }}>
          <Form.Field name="amount">
            <div className="flex items-baseline justify-between">
              <Form.Label className="text-xl font-medium text-white">
                <p className="text-sm mb-2">
                  {`Balance : ${
                    userBalances[vaultToken.name.toUpperCase()] || 0
                  }`}
                </p>
              </Form.Label>
            </div>
            <div className="flex">
              <Form.Control asChild>
                <input
                  className="box-border w-full bg-white shadow-black inline-flex h-[35px] items-center justify-center rounded-[4px] px-[10px] text-[15px] leading-none text-black outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  onChange={event => {
                    (/^\d*\.{0,1}\d*$/.test(event.target.value) ||
                      event.target.value === '') &&
                      setAmount(event.target.value);
                  }}
                  type="text"
                  value={amountInput}
                  defaultValue={0}
                />
              </Form.Control>
            </div>
            <Form.Message
              className="text-[13px] text-primary opacity-[0.8]"
              match={'valueMissing'}>
              Please input your amount
            </Form.Message>
            <Form.Message
              className="text-[13px] text-primary opacity-[0.8]"
              match={'badInput'}>
              Invalid input.
            </Form.Message>
            <Form.Message
              className="text-[13px] text-primary opacity-[0.8]"
              match={value => {
                return (
                  Number.parseFloat(value) >
                  userBalances[vaultToken.name.toUpperCase()]
                );
              }}>
              Greater than the balance.
            </Form.Message>
          </Form.Field>
          <Form.Submit asChild>
            <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
              Add
            </button>
          </Form.Submit>
        </Form.Root>
      </div>
    );
  };

  return (
    <div>
      <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
        <div className="p-3">
          <p className="text-xl text-center">Market Maker Vaults</p>
        </div>
      </div>
      <div className="flex md:flex-row flex-col">
        {currentGlobalVault && (
          <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
            <div className="p-3">
              <SelectMMPair />
              {`Total Shares: ${currentGlobalVault.total_shares}`}
              <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
                <p className="text-xl text-left">Native Asset</p>
                {showTokenAmount({
                  vaultToken: currentGlobalVault.native,
                })}
              </div>
              <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
                <p className="text-xl text-left">Foreign Assets</p>
                {showForeignAssets(currentGlobalVault.foreign)}
              </div>
            </div>
          </div>
        )}
        {currentUserVault && (
          <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
            <div className="p-3">
              <p className="text-xl text-center">My Liquidity</p>
              <p>{`Shares: ${currentUserVault.shares}`}</p>
              {`Unclaimed Rewards: ${currentUserVault.unclaimed} TEZ`}
              {/* {showAddLiquidity({
                vaultToken: getMVault(current_vault).global.native,
                userBalances: userBalances,
              })}
              {showRemoveLiquidity({
                vaultToken: getMVault(current_vault).global.native,
              })}
              {showClaimRewards({
                vaultToken: getMVault(current_vault).global.native,
              })} */}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
export default MMVaultComponent;
