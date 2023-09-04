import React from 'react';
import * as RadioGroup from '@radix-ui/react-radio-group';
import { useDispatch } from 'react-redux';
import { PriceStrategy } from 'src/types';
import { updatePriceStrategy } from 'src/actions';

const PriceStrategyComponent = () => {
  const dispatch = useDispatch();

  return (
    <div className="flex flex-col items-center border-2 border-solid border-lightgray p-4 my-2 md:mr-4 pb-4 md:text-base text-sm">
      <p className="p-4 md:mb-5 mb-4 text-base">
        Select the price you want to sell
      </p>
      <form>
        <RadioGroup.Root
          className="flex flex-col md:gap-10 gap-5"
          defaultValue={PriceStrategy.EXACT}
          // value={currentPriceStrategy}
          onValueChange={
            // price => console.warn(price)
            (price: PriceStrategy) => dispatch(updatePriceStrategy(price))
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
