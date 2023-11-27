import React, { useCallback, useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChevronDown,
  faCheck,
  faChevronUp,
} from '@fortawesome/free-solid-svg-icons';
import { useSelector } from 'react-redux';
import {
  currentSwapSelector,
  //tokensSelector,
  swapsSelector,
  displayTokensSelector,
} from '@/reducers';
import { useDispatch } from 'react-redux';
import { changePair } from '@/actions';
import { DisplaySwap } from '@/types';
import Image from 'next/image';
import {
  ensureMapTypeOnSwaps,
  ensureMapTypeOnDisplayTokens,
} from '@/utils/utils';

interface SelectPairProps {
  isFrom: boolean;
}

const SelectPair = ({ isFrom }: SelectPairProps) => {
  const { swap, isReverse } = useSelector(currentSwapSelector);
  const dispatch = useDispatch();

  //const tokens = useSelector(tokensSelector);
  const swaps = useSelector(swapsSelector);
  const displayTokens = useSelector(displayTokensSelector);
  const [availableSwapPairs, setAvailableSwapPairs] = useState<DisplaySwap[]>(
    []
  );

  const emptyDisplayToken = () => {
    return {
      name: '',
      address: '',
      icon: '',
    };
  };

  useEffect(() => {

    const mappedSwaps = ensureMapTypeOnSwaps(swaps);
    const mappedDisplayTokens = ensureMapTypeOnDisplayTokens(displayTokens);
    const swapPairs = Array.from(mappedSwaps).map(([k, v]) => {
      const to = mappedDisplayTokens.get(v.swap.to);
      const from = mappedDisplayTokens.get(v.swap.from);

      let ds: DisplaySwap = {
        pair: k,
        to: to || emptyDisplayToken(),
        from: from || emptyDisplayToken(),
      };
      return ds;
    });


    setAvailableSwapPairs(swapPairs);
  }, [dispatch, swaps, displayTokens]);



  const displayValue = useCallback(() => {
    if (isReverse && isFrom) return swap.to?.name;
    if (isReverse && !isFrom) return swap.from?.name;
    if (!isReverse && isFrom) return swap.from?.name;
    if (!isReverse && !isFrom) return swap.to?.name;
    return swap.from?.name;
  }, [isReverse, isFrom, swap]);

  return (
    <Select.Root
      value={displayValue()}
      onValueChange={value => {
        console.info('swaps', swaps);
        console.info('display tokens', displayTokens);
        console.info('swap', swap);
        console.info('value', value);
        console.info('isFrom', isFrom);
        if (value.length > 0) {
          dispatch(changePair(value, false));
        }
      }}
    >
      <Select.Trigger className="flex items-center text-dark w-[200px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
        <Select.Value
          placeholder={isReverse ? swap.to?.name : swap.from?.name}
        />
        <Select.Icon className="text-dark">
          <FontAwesomeIcon icon={faChevronDown} />
        </Select.Icon>
      </Select.Trigger>
      <Select.Portal className="w-[15rem]">
        <Select.Content className="overflow-hidden bg-white rounded-md text-dark">
          <Select.ScrollUpButton className="flex items-center justify-right h-[25px] cursor-default">
            <FontAwesomeIcon icon={faChevronUp} />
          </Select.ScrollUpButton>
          <Select.Viewport className="p-4">
            <Select.Group>
              {availableSwapPairs.map(sp => (
                <SelectItem
                  value={sp.pair}
                  key={sp.pair}
                >
                  <div className="flex items-left">
                    {sp.from.icon ? (
                      <Image
                        src={sp.from.icon}
                        alt={`${sp.from.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                      />
                    ) : (
                      <Image
                        src={`/${sp.from.name}-icon.png`}
                        loader={({ src }) => src}
                        alt={`${sp.from.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                        unoptimized
                      />
                    )}
                    <p>{sp.from.name}</p>
                    <p>-</p>
                    <p>{sp.to.name}</p>
                    {sp.to.icon ? (
                      <Image
                        src={sp.to.icon}
                        alt={`${sp.to.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                      />
                    ) : (
                      <Image
                        src={`/${sp.to.name}-icon.png`}
                        loader={({ src }) => src}
                        alt={`${sp.to.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                        unoptimized
                      />
                    )}
                  </div>
                </SelectItem>
              ))}
            </Select.Group>
          </Select.Viewport>
          <Select.ScrollDownButton className="flex items-center justify-right h-[25px] cursor-default">
            <FontAwesomeIcon icon={faChevronDown} />
          </Select.ScrollDownButton>
        </Select.Content>
      </Select.Portal>
    </Select.Root>
  );
};

// eslint-disable-next-line react/display-name
const SelectItem = React.forwardRef<
  HTMLDivElement,
  {
    children: React.ReactNode;
    className?: string;
    value: string;
    disabled?: boolean;
  }
>(({ children, className, disabled, ...props }, forwardedRef) => {
  return (
    <Select.Item
      disabled={disabled}
      className={`${
        disabled
          ? 'data-[highlighted]:cursor-not-allowed data-[highlighted]:bg-white'
          : ''
      } text-base text-dark rounded flex items-center h-[25px] pr-[35px] pl-[25px] relative select-none data-[highlighted]:outline-none data-[highlighted]:bg-hovergray disabled:cursor-not-allowed`}
      {...props}
      ref={forwardedRef}
    >
      <Select.ItemText>{children}</Select.ItemText>
      <Select.ItemIndicator className="absolute left-0 w-6 inline-flex items-center justify-center">
        <FontAwesomeIcon icon={faCheck} />
      </Select.ItemIndicator>
    </Select.Item>
  );
});

export default SelectPair;
