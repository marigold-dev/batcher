import React from 'react';
import { BatcherInfoProps } from '../../utils/types';
import BatcherStepper from '../BatcherStepper';
import { useSelector } from 'react-redux';
import {
  batcherStatusSelector,
  currentSwapSelector,
  remainingTimeSelector,
  userBalancesSelector,
} from '../../src/reducers';
import { BatcherStatus } from '../../src/types';

const BatcherInfo: React.FC<BatcherInfoProps> = ({
  userAddress,
  tokenPair,
  buyBalance,
  sellBalance,
  buyTokenName,
  sellTokenName,
  rate,
  // status,
  openTime,
  updateAll,
  setUpdateAll,
  batchNumber,
}: BatcherInfoProps) => {
  const userBalances = useSelector(userBalancesSelector);
  const currentSwap = useSelector(currentSwapSelector);

  const status = useSelector(batcherStatusSelector);
  const remainingTime = useSelector(remainingTimeSelector);

  return (
    <div className="font-custom">
      <div className="flex flex-row p-3">
        <div className="flex flex-direction-col border-solid border-2 border-[#7B7B7E]">
          <div className="p-3">
            <p className="text-xl font-mono">Batcher Time Remaining</p>
            {status === BatcherStatus.NONE ? (
              <p className="text-l">No open Batch</p>
            ) : (
              <BatcherStepper />
            )}
            {status === BatcherStatus.OPEN ? (
              <div className="p-5 border-solid border-2 border-[#7B7B7E]">
                <p className="p-4">{remainingTime + ' min'}</p>
              </div>
            ) : (
              <div />
            )}
            {batchNumber > 0 ? (
              <div className="p-5 border-solid border-2 border-[#7B7B7E]">
                <p className="p-4">
                  {`${
                    status === BatcherStatus.CLEARED
                      ? 'LastBatch'
                      : 'Current batch'
                  } ${batchNumber}`}
                </p>
              </div>
            ) : (
              <div></div>
            )}
          </div>
        </div>
        <div className="border-[#7B7B7E] border-2 border-solid">
          <div className="flex flex-col batcher-balance-title">
            <div className="flex border-solid border-2 border-[#7B7B7E]">
              <p className="batcher-title p-3">Balances</p>
              <p className="batcher-title p-3">
                {currentSwap.isReverse
                  ? `${currentSwap.swap.to.name} ${
                      userBalances[currentSwap.swap.to.name.toUpperCase()] || 0
                    }`
                  : `${currentSwap.swap.from.token.name} ${
                      userBalances[
                        currentSwap.swap.from.token.name.toUpperCase()
                      ] || 0
                    }`}
              </p>
              <p className="batcher-title p-3">
                {currentSwap.isReverse
                  ? `${currentSwap.swap.from.token.name} ${
                      userBalances[
                        currentSwap.swap.from.token.name.toUpperCase()
                      ] || 0
                    }`
                  : `${currentSwap.swap.to.name} ${
                      userBalances[currentSwap.swap.to.name.toUpperCase()] || 0
                    }`}
              </p>
            </div>
          </div>
          <div className="flex flex-row border-[#7B7B7E] border-2 border-solid">
            <p className="p-4">Address</p>
            {userAddress ? (
              <p>{userAddress}</p>
            ) : (
              <p className="p-4">No Wallet connected</p>
            )}
          </div>
          <div className="flex flex-row border-[#7B7B7E] border-2 border-solid">
            <p className="p-4">Oracle Price</p>
            <p className="p-4">
              {rate} {tokenPair}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BatcherInfo;
