import React from 'react';
import { useSelector } from 'react-redux';
import { batcherStatusSelector } from '../reducers';
import { BatcherStatus } from '../types';

const Square = ({ isActive }: { isActive: boolean }) => (
  <div
    className={`md:w-8 md:h-8 w-6 h-6 ${
      isActive ? 'bg-[#6FE17A]' : 'bg-[#CECCCC]'
    }`}
  />
);

const Dot = ({ isActive }: { isActive: boolean }) => (
  <div
    className={`md:text-3xl text-l ${
      isActive ? 'text-[#6FE17A]' : 'text-[#CECCCC]'
    }`}>
    -
  </div>
);

const BatcherStepper = () => {
  const status = useSelector(batcherStatusSelector);

  return (
    <div className="flex flex-col items-center">
      <div className="flex md:gap-3 gap-1 px-4 py-3">
        <div className="flex flex-col items-center md:gap-5 gap-3 md:text-xl text-xs">
          <Square isActive={status !== BatcherStatus.NONE} />
          <p>Started</p>
        </div>

        <Dot isActive={status !== BatcherStatus.NONE} />
        <Dot isActive={status !== BatcherStatus.NONE} />
        <Dot isActive={status !== BatcherStatus.NONE} />

        <div className="flex flex-col items-center md:gap-5 gap-3 md:text-xl text-xs">
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

        <div className="flex flex-col items-center md:gap-5 gap-3 md:text-xl text-xs">
          <Square isActive={status === BatcherStatus.CLEARED} />
          <p>Cleared</p>
        </div>
      </div>
    </div>
  );
};

export default BatcherStepper;
