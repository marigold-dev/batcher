import React from 'react';
import * as RadioGroup from '@radix-ui/react-radio-group';
import { useDispatch } from 'react-redux';
import { PriceStrategy } from 'src/types';
import { updatePriceStrategy } from 'src/actions';
import Tooltip from './Tooltip';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faQuestionCircle } from '@fortawesome/free-solid-svg-icons';

const PriceStrategyComponent = () => {
  const dispatch = useDispatch();

  return (
    <div className="flex flex-col items-center border-2 border-solid border-lightgray p-4 my-2 md:mr-4 pb-4 md:text-base text-sm">
      <div className="flex items-center">
        <p className="p-4  text-base">Select the price you want to sell</p>
        <Tooltip
          text={
            <>
              <p>
                {
                  'As Batcher uses a future Oracle price to execute swaps, a user cannot select a specific price to execute the swap at. When using Batcher, a user would rather select one of the price tranches when placing a swap. The available tranches are all given in the context of the future oracle price. Those tranches are:'
                }
                <ul className="mt-2">
                  <li>- Oracle price + 10 basis points (Better Price)</li>
                  <li>- Oracle price</li>
                  <li>- Oracle price - 10 basis points (Worse Price)</li>
                </ul>
              </p>
              <p className="mt-4">
                {'More informations on '}
                <a
                  className="underline"
                  href="https://www.marigold.dev/batcher"
                  target="_blank">
                  marigold.dev/batcher
                </a>
              </p>
            </>
          }>
          <FontAwesomeIcon icon={faQuestionCircle} />
        </Tooltip>
      </div>
      <form>
        <RadioGroup.Root
          className="flex flex-col md:gap-10 gap-5 md:mt-5 mt-4"
          defaultValue={PriceStrategy.EXACT}
          onValueChange={(price: PriceStrategy) =>
            dispatch(updatePriceStrategy(price))
          }
          aria-label="View density">
          <div className="flex items-center">
            <RadioGroup.Item
              className="bg-white w-6 h-6 rounded-full shadow-[0_0_0_2px] shadow-[black] hover:bg-gray-200 outline-none cursor-pointer"
              value={PriceStrategy.WORSE}
              id="r1">
              <RadioGroup.Indicator className="flex items-center justify-center w-full h-full after:block after:w-[11px] after:h-[11px] after:rounded-[50%] after:bg-[black]" />
            </RadioGroup.Item>
            <label
              className="text-white md:text-base text-sm leading-none pl-[15px]"
              htmlFor="r1">
              Worse Price / Better Fill
            </label>
          </div>
          <div className="flex items-center">
            <RadioGroup.Item
              className="bg-white w-6 h-6 rounded-full shadow-[0_0_0_2px] shadow-[black] hover:bg-gray-200 outline-none cursor-pointer"
              value={PriceStrategy.EXACT}
              id="r2">
              <RadioGroup.Indicator className="flex items-center justify-center w-full h-full relative after:content-[''] after:block after:w-[11px] after:h-[11px] after:rounded-[50%] after:bg-[black]" />
            </RadioGroup.Item>
            <label
              className="text-white md:text-base text-sm leading-none pl-[15px]"
              htmlFor="r2">
              Oracle Price
            </label>
          </div>
          <div className="flex items-center">
            <RadioGroup.Item
              className="bg-white w-6 h-6 rounded-full shadow-[0_0_0_2px] shadow-[black] hover:bg-gray-200 outline-none cursor-pointer"
              value={PriceStrategy.BETTER}
              id="r3">
              <RadioGroup.Indicator className="flex items-center justify-center w-full h-full relative after:content-[''] after:block after:w-[11px] after:h-[11px] after:rounded-[50%] after:bg-[black]" />
            </RadioGroup.Item>
            <label
              className="text-white md:text-base text-sm leading-none pl-[15px]"
              htmlFor="r3">
              Better Price / Worse Fill
            </label>
          </div>
        </RadioGroup.Root>
      </form>
    </div>
  );
};

export default PriceStrategyComponent;
