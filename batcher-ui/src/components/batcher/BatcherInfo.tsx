import React from 'react';
import BatcherStepper from './BatcherStepper';
import { useSelector } from 'react-redux';
import {
  batchNumberSelector,
  batcherStatusSelector,
  currentPairSelector,
  oraclePriceSelector,
  remainingTimeSelector,
} from '@/reducers';
import { BatcherStatus } from '@/types';

const BatcherInfo = () => {
  const tokenPair = useSelector(currentPairSelector);
  const batchNumber = useSelector(batchNumberSelector);

  const status = useSelector(batcherStatusSelector);
  const remainingTime = useSelector(remainingTimeSelector);
  const oraclePrice = useSelector(oraclePriceSelector);

  return (
    <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
      <div className="p-3">
        <p className="text-xl text-center">Batcher Status</p>
        {status === BatcherStatus.NONE ? (
          <p className="text-l text-center my-4">No open Batch</p>
        ) : (
          <BatcherStepper />
        )}
        {status === BatcherStatus.OPEN ? (
          <div className="p-5 border-solid border-b-0 border-2 border-lightgray md:text-base text-sm">
            <p>{`Remaining time: ${remainingTime} min`}</p>
          </div>
        ) : (
          <div />
        )}
        {batchNumber > 0 ? (
          <div className="p-5 border-solid border-b-0 border-t-2 border-2 border-lightgray md:text-base text-sm">
            <p>
              {`${
                status === BatcherStatus.CLEARED
                  ? 'Last batch: '
                  : 'Current batch: '
              } ${batchNumber}`}
            </p>
          </div>
        ) : (
          <div></div>
        )}
        <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
          <p>{`Oracle Price: ${oraclePrice} ${tokenPair}`}</p>
        </div>
      </div>
    </div>
  );
};

export default BatcherInfo;
