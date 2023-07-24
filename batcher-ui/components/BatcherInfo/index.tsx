import React, { useEffect } from 'react';
import { BatcherInfoProps, BatcherStatus } from '../../extra_utils/types';
import BatcherStepper from '../BatcherStepper';
import { parseISO, add, differenceInMinutes } from 'date-fns';

const BatcherInfo: React.FC<BatcherInfoProps> = ({
  userAddress,
  tokenPair,
  buyBalance,
  sellBalance,
  buyTokenName,
  sellTokenName,
  inversion,
  rate,
  status,
  openTime,
  updateAll,
  setUpdateAll,
  batchNumber,
}: BatcherInfoProps) => {
  const triggerUpdate = () => {
    if (status === BatcherStatus.OPEN && openTime) {
      setTimeout(function () {
        const u = !updateAll;
        setUpdateAll(u);
      }, 600000);
    }
  };

  useEffect(() => {
    triggerUpdate();
  }, [status]);

  const get_batch_prefix = () => {
    if (status == BatcherStatus.CLEARED) {
      return 'Last Batch ';
    }
    return 'Current Batch ';
  };

  const get_time_difference = () => {
    if (status === BatcherStatus.OPEN && openTime) {
      const now = new Date();
      const open = parseISO(openTime);
      const batcherClose = add(open, { minutes: 10 });
      const diff = differenceInMinutes(batcherClose, now);
      if (diff < 0) {
        return 0;
      } else {
        return diff;
      }
    }
    return 0;
  };

  return (
    <div className="font-custom">
      <div className="flex flex-row p-3">
        <div className="flex flex-direction-col border-solid border-2 border-[#7B7B7E]">
          <div className="p-3">
            <p className="text-xl font-mono">Batcher Time Remaining</p>
            {status === BatcherStatus.NONE ? (
              <p className="text-l">No open Batch</p>
            ) : (
              <BatcherStepper status={status} />
            )}
            {status === BatcherStatus.OPEN ? (
              <div className="p-5 border-solid border-2 border-[#7B7B7E]">
                <p className="p-4">{get_time_difference() + ' min'}</p>
              </div>
            ) : (
              <div />
            )}
            {batchNumber > 0 ? (
              <div className="p-5 border-solid border-2 border-[#7B7B7E]">
                <p className="p-4">{get_batch_prefix() + '#' + batchNumber}</p>
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
                {inversion
                  ? buyBalance + ' ' + buyTokenName
                  : sellBalance + ' ' + sellTokenName}
              </p>
              <p className="batcher-title p-3">
                {inversion
                  ? sellBalance + ' ' + sellTokenName
                  : buyBalance + ' ' + buyTokenName}
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
