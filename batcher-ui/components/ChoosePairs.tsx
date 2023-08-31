import * as Dialog from '@radix-ui/react-dialog';
import React, { useState } from 'react';
import * as RadioGroup from '@radix-ui/react-radio-group';
import { useDispatch } from 'react-redux';
import { changePair } from '../src/actions';
import { getPairsInformations } from '../utils/utils';
import { faXmark, faGear } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const ChoosePairs = () => {
  const dispatch = useDispatch();

  const [pair, setPair] = useState<string>('tzBTC/USDT');

  return (
    <Dialog.Root>
      <Dialog.Trigger asChild>
        <button className="md:mx-4 mx-0">
          <FontAwesomeIcon
            icon={faGear}
            color="white"
            className="hover:text-lightgray"
            size="2xl"
          />
        </button>
      </Dialog.Trigger>

      <Dialog.Portal>
        <Dialog.Overlay className="bg-[black] fixed inset-0 opacity-75" />
        <Dialog.Content className="fixed top-[50%] left-[50%] max-h-[85vh] w-[90vw] max-w-[450px] translate-x-[-50%] translate-y-[-50%] rounded-[6px] bg-white p-[25px] shadow-[hsl(206_22%_7%_/_35%)_0px_10px_38px_-10px,_hsl(206_22%_7%_/_20%)_0px_10px_20px_-15px] focus:outline-none">
          <Dialog.Title className="text-[black] mb-6 text-md font-custom">
            Choose pairs swap
          </Dialog.Title>

          <RadioGroup.Root
            className="flex flex-col gap-5"
            defaultValue={'tzBTC/USDT'}
            value={pair}
            onValueChange={setPair}
            aria-label="View density">
            <div className="flex items-center">
              <RadioGroup.Item
                className="bg-white w-6 h-6 rounded-full shadow-[0_0_0_2px] shadow-[black] hover:bg-gray-200 outline-none cursor-pointer"
                value="tzBTC/USDT"
                id="r1">
                <RadioGroup.Indicator className="flex items-center justify-center w-full h-full relative after:content-[''] after:block after:w-[11px] after:h-[11px] after:rounded-[50%] after:bg-[black]" />
              </RadioGroup.Item>
              <label
                className="text-black text-[15px] leading-none pl-[15px]"
                htmlFor="r1">
                {'tzBTC/USDT'}
              </label>
            </div>
            <div className="flex items-center">
              <RadioGroup.Item
                className="bg-white w-6 h-6 rounded-full shadow-[0_0_0_2px] shadow-[black] hover:bg-gray-200 outline-none cursor-pointer"
                value="tzBTC/EURL"
                id="r2">
                <RadioGroup.Indicator className="flex items-center justify-center w-full h-full relative after:content-[''] after:block after:w-[11px] after:h-[11px] after:rounded-[50%] after:bg-[black]" />
              </RadioGroup.Item>
              <label
                className="text-black text-[15px] leading-none pl-[15px]"
                htmlFor="r2">
                {'tzBTC/EURL'}
              </label>
            </div>
          </RadioGroup.Root>

          <div className="mt-[25px] flex justify-end font-custom">
            <Dialog.Close asChild>
              <button
                className="bg-primary text-white inline-flex h-[35px] items-center justify-center rounded-[4px] px-[15px] hover:bg-red-500"
                onClick={() => {
                  getPairsInformations(
                    pair,
                    process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || ''
                  ).then(console.warn);
                  dispatch(changePair(pair));
                }}>
                Save
              </button>
            </Dialog.Close>
          </div>
          <Dialog.Close asChild>
            <button
              className="text-[black] absolute top-[10px] right-[10px] inline-flex h-[25px] w-[25px] items-center justify-center"
              aria-label="Close">
              <FontAwesomeIcon icon={faXmark} />
            </button>
          </Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
};

export default ChoosePairs;