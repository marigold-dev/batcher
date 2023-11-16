import React, { useCallback, useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChevronDown,
  faCheck,
  faChevronUp,
} from '@fortawesome/free-solid-svg-icons';
import { useSelector } from 'react-redux';
import { currentSwapSelector, tokensSelector, swapsSelector } from '@/reducers';
import { useDispatch } from 'react-redux';
import { changePair, newError } from '@/actions';
import { ValidSwap } from '@/types';
import Image from 'next/image';
import {
  getLexicographicalPairName,
  getTokensMetadata,
} from '@/utils/token-manager';
import { ensureMapTypeOnSwaps } from '@/utils/utils';

interface SelectPairProps {
  isFrom: boolean;
}

const SelectPair = ({ isFrom }: SelectPairProps) => {
  const { swap, isReverse } = useSelector(currentSwapSelector);
  const dispatch = useDispatch();

  const tokens = useSelector(tokensSelector);
  const swaps = useSelector(swapsSelector);
  const [availableTokens, setAvailableTokens] = useState<any[]>([]);
  const [availableSwaps, setAvailableSwaps] = useState<string[]>([]);

  const displayValue = useCallback(() => {
    if (isReverse && isFrom) return swap.to.name;
    if (isReverse && !isFrom) return swap.from.token.name;
    if (!isReverse && isFrom) return swap.from.token.name;
    if (!isReverse && !isFrom) return swap.to.name;
    return swap.from.token.name;
  }, [isReverse, isFrom, swap]);

  useEffect(() => {
    getTokensMetadata().then(
      (
        tokens: { name: string; address: string; icon: string | undefined }[]
      ) => {
        setAvailableTokens(tokens);
        console.info('swaps - before', swaps);
        const swapsAsMap: Map<string, ValidSwap> = ensureMapTypeOnSwaps(swaps);
        console.info('swaps - dispatch', swapsAsMap);
        console.info('swaps keys - dispatch', swapsAsMap.keys());
        const swps: string[] = Array.from(swapsAsMap.keys());
        console.info('swps - dispatch', swps);
        setAvailableSwaps(swps);
      }
    );
  }, [dispatch, tokens, swaps]);

  const isValidPair = (pair: string) => availableSwaps.includes(pair);

  const invalidSwap = (pairName: string) => {
    dispatch(
      newError(
        pairName +
          ' is not a valid pair. Only ' +
          availableSwaps.join() +
          'are supported.'
      )
    );
  };

  const is_reversed = (pair: string, to: string, from: string) => {
    const swap = ensureMapTypeOnSwaps(swaps).get(pair);
    return to === swap?.swap.to && from === swap?.swap.from;
  };

  return (
    <Select.Root
      value={displayValue()}
      onValueChange={value => {
        console.info('availableSwaps', availableSwaps);
        console.info('swaps', swaps);
        console.info('swap', swap);
        console.info('value', value);
        console.info('isFrom', isFrom);
        const from = isFrom ? `${swap.to.name}` : `${value}`;
        const to = isFrom ? `${value}` : `${swap.from.token.name}`;
        const pairName = getLexicographicalPairName(to, from);
        const is_valid = isValidPair(pairName);
        if (is_valid) {
          const reversed = is_reversed(pairName, to, from);
          dispatch(changePair(pairName, reversed));
        } else {
          invalidSwap(pairName);
        }
      }}
    >
      <Select.Trigger className="flex items-center text-dark w-[200px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
        <Select.Value
          placeholder={isReverse ? swap.to.name : swap.from.token.name}
        />
        <Select.Icon className="text-dark">
          <FontAwesomeIcon icon={faChevronDown} />
        </Select.Icon>
      </Select.Trigger>
      <Select.Portal className="w-[7rem]">
        <Select.Content className="overflow-hidden bg-white rounded-md text-dark">
          <Select.ScrollUpButton className="flex items-center justify-center h-[25px] cursor-default">
            <FontAwesomeIcon icon={faChevronUp} />
          </Select.ScrollUpButton>
          <Select.Viewport className="p-2">
            <Select.Group>
              {availableTokens.map(t => (
                <SelectItem
                  value={t.name}
                  key={t.name}
                  disabled={
                    isReverse
                      ? swap.to.name === t.name
                      : swap.from.token.name === t.name
                  }
                >
                  <div className="flex items-center">
                    {t.icon ? (
                      <Image
                        src={t.icon}
                        alt={`${t.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                      />
                    ) : (
                      <Image
                        src={`/${t.name}-icon.png`}
                        loader={({ src }) => src}
                        alt={`${t.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
                        unoptimized
                      />
                    )}
                    <p>{t.name}</p>
                  </div>
                </SelectItem>
              ))}
            </Select.Group>
          </Select.Viewport>
          <Select.ScrollDownButton className="flex items-center justify-center h-[25px] cursor-default">
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
