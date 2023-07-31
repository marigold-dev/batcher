import React from 'react';
import { BatcherActionProps, ContentType } from '../../utils/types';

const BatcherAction: React.FC<BatcherActionProps> = ({
  content,
  setContent,
}: BatcherActionProps) => {
  return (
    <div className="font-custom flex flex-row justify-evenly border-solid border-2 border-[#7B7B7E]">
      <div>
        <button
          className="border-2 border-solid border-[#ff4d4f] bg-[#1C1D22] p-2 hover:text-[#1C1D22] hover:bg-[#ff4d4f] focus:text-[#1C1D22] focus:bg-[#ff4d4f] hover:border-[#7B7B7E] focus:border-[#7B7B7E]"
          onClick={() => setContent(ContentType.SWAP)}>
          Swap
        </button>
      </div>
      <div>
        <button
          className="border-2 border-solid border-[#ff4d4f] bg-[#1C1D22] p-2 hover:text-[#1C1D22] hover:bg-[#ff4d4f] focus:text-[#1C1D22] focus:bg-[#ff4d4f] hover:border-[#7B7B7E] focus:border-[#7B7B7E]"
          onClick={() => setContent(ContentType.VOLUME)}>
          Volume
        </button>
      </div>
      <button
        className="border-2 border-solid border-[#ff4d4f] bg-[#1C1D22] p-2 hover:text-[#1C1D22] hover:bg-[#ff4d4f] focus:text-[#1C1D22] focus:bg-[#ff4d4f] hover:border-[#7B7B7E] focus:border-[#7B7B7E]"
        onClick={() => setContent(ContentType.REDEEM_HOLDING)}>
        Redeem Holdings
      </button>
      <button
        className="border-2 border-solid border-[#ff4d4f] bg-[#1C1D22] p-2 hover:text-[#1C1D22] hover:bg-[#ff4d4f] focus:text-[#1C1D22] focus:bg-[#ff4d4f] hover:border-[#7B7B7E] focus:border-[#7B7B7E]"
        onClick={() => setContent(ContentType.ABOUT)}>
        About
      </button>
    </div>
  );
};

export default BatcherAction;
