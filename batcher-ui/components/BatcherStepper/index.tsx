import React from 'react';
import { useSelector } from 'react-redux';
import { batcherStatusSelector } from '../../src/reducers';
import { BatcherStatus } from '../../src/types';

const Square = ({ isActive }: { isActive: boolean }) => (
  <div className={`w-8 h-8 ${isActive ? 'bg-[#6FE17A]' : 'bg-[#CECCCC]'}`} />
);

const Dot = ({ isActive }: { isActive: boolean }) => (
  <div className={`text-3xl ${isActive ? 'text-[#6FE17A]' : 'text-[#CECCCC]'}`}>
    -
  </div>
);

const BatcherStepper = () => {
  const status = useSelector(batcherStatusSelector);

  return (
    <div className="flex flex-col">
      <div className="flex gap-3 px-1 py-3">
        <div className="flex flex-col items-center gap-5">
          <Square isActive={status !== BatcherStatus.NONE} />
          <p>Started</p>
        </div>

        <Dot isActive={status !== BatcherStatus.NONE} />
        <Dot isActive={status !== BatcherStatus.NONE} />
        <Dot isActive={status !== BatcherStatus.NONE} />

        <div className="flex flex-col items-center gap-5">
          <Square
            isActive={
              status === BatcherStatus.CLOSED ||
              status === BatcherStatus.CLEARED
            }
          />
          <p>Closed</p>
        </div>

        <Dot isActive={status === BatcherStatus.CLEARED} />
        <Dot isActive={status === BatcherStatus.CLEARED} />
        <Dot isActive={status === BatcherStatus.CLEARED} />

        <div className="flex flex-col items-center gap-5">
          <Square isActive={status === BatcherStatus.CLEARED} />
          <p>Cleared</p>
        </div>
      </div>
    </div>
  );
};

export default BatcherStepper;
