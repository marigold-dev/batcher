import React, { useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import * as Form from '@radix-ui/react-form';
import { MVault, VaultToken } from '../types';
import SelectMMPair from './SelectMMPair';
import { getMVault } from 'src/utils/utils';
import { useSelector } from 'react-redux';
import { userBalancesSelector } from '../reducers';

interface MMVaultProps {
  vaults: Map<string, MVault>;
  current_vault: MVault;
}
const MMVaultComponent = ({ vaults, current_vault }: MMVaultProps) => {
  const userBalances = useSelector(userBalancesSelector);
  const [amountInput, setAmount] = useState<string>('0');

  const showTokenAmount = ({ vaultToken }: { vaultToken: VaultToken }) => (
    <div className="p-3">
      <p className="text-xl text-center">
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
  };

  const claimRewards = async ({ tokenName }: { tokenName: string }) => {
    console.log(tokenName);
  };

  const showClaimRewards = ({ vaultToken }: { vaultToken: VaultToken }) => {
    return (
      <div className="flex flex-col grow my-2">
        <div className="p-5 flex flex-col md:flex-row justify-center border-2 border-solid border-lightgray md:text-base text-sm">
          <Form.Root
            className="flex flex-col items-strech"
            onSubmit={event => {
              event.preventDefault();
              claimRewards({
                tokenName: vaultToken.name,
              });
            }}
          >
            <Form.Submit asChild>
              <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
                Claim Rewards
              </button>
            </Form.Submit>
          </Form.Root>
        </div>
      </div>
    );
  };
  const removeLiquidity = async ({ tokenName }: { tokenName: string }) => {
    console.log(tokenName);
  };

  const showRemoveLiquidity = ({ vaultToken }: { vaultToken: VaultToken }) => {
    return (
      <div className="flex flex-col grow my-2">
        <div className="p-5 flex flex-col md:flex-row justify-center border-2 border-solid border-lightgray md:text-base text-sm">
          <Form.Root
            className="flex flex-col items-strech"
            onSubmit={event => {
              event.preventDefault();
              removeLiquidity({
                tokenName: vaultToken.name,
              });
            }}
          >
            <Form.Submit asChild>
              <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
                Remove Liquidity
              </button>
            </Form.Submit>
          </Form.Root>
        </div>
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
        <div className="p-5 flex flex-col md:flex-row justify-center border-2 border-solid border-lightgray md:text-base text-sm">
          <Form.Root
            className="flex flex-col items-strech"
            onSubmit={event => {
              event.preventDefault();
              addLiquidity({
                tokenName: vaultToken.name,
                tokenAmount: parseInt(amountInput),
              });
            }}
          >
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
                match={'valueMissing'}
              >
                Please input your amount
              </Form.Message>
              <Form.Message
                className="text-[13px] text-primary opacity-[0.8]"
                match={'badInput'}
              >
                Invalid input.
              </Form.Message>
              <Form.Message
                className="text-[13px] text-primary opacity-[0.8]"
                match={value => {
                  return (
                    Number.parseFloat(value) >
                    userBalances[vaultToken.name.toUpperCase()]
                  );
                }}
              >
                Greater than the balance.
              </Form.Message>
            </Form.Field>
            <Form.Submit asChild>
              <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
                Add Liquidity
              </button>
            </Form.Submit>
          </Form.Root>
        </div>
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
      <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
        <div className="p-3">
          <p className="text-xl text-left">Global</p>
          <SelectMMPair vaults={vaults} current_vault={current_vault} />
          <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
            <p>{`Total Shares: ${
              getMVault(current_vault).global.total_shares
            }`}</p>
          </div>
          <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
            <p className="text-xl text-left">Native Asset</p>
            <p>
              {showTokenAmount({
                vaultToken: getMVault(current_vault).global.native,
              })}
            </p>
          </div>
          <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
            <p className="text-xl text-left">Foreign Assets</p>
            <p>{showForeignAssets(getMVault(current_vault).global.foreign)}</p>
          </div>
        </div>
      </div>
      <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
        <div className="p-3">
          <p className="text-xl text-center">User</p>
          <p>{`Shares: ${getMVault(current_vault).user.shares}`}</p>
          <p>{`Unclaimed Rewards: ${
            getMVault(current_vault).user.unclaimed
          } TEZ`}</p>
        </div>
        <div className="p-3">
          <p>
            {showClaimRewards({
              vaultToken: getMVault(current_vault).global.native,
            })}
            {showAddLiquidity({
              vaultToken: getMVault(current_vault).global.native,
              userBalances: userBalances,
            })}
            {showRemoveLiquidity({
              vaultToken: getMVault(current_vault).global.native,
            })}
          </p>
        </div>
      </div>
    </div>
  );
};
export default MMVaultComponent;
