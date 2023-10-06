import React, { useCallback, useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChevronDown,
  faCheck,
  faChevronUp,
} from '@fortawesome/free-solid-svg-icons';
import { useSelector } from 'react-redux';
import { currentSwapSelector } from 'src/reducers';
import { useDispatch } from 'react-redux';
import { changePair } from 'src/actions';
import { getTokensMetadata } from 'src/utils/utils';
import Image from 'next/image';
import { TokenNames } from 'src/types';

interface SelectPairProps {
  isFrom: boolean;
}

const SelectPair = ({ isFrom }: SelectPairProps) => {
  const { swap, isReverse } = useSelector(currentSwapSelector);
  const dispatch = useDispatch();

  const [availableTokens, setAvailableTokens] = useState<any[]>([]);

  const displayValue = useCallback(() => {
    if (isReverse && isFrom) return swap.to.name;
    if (isReverse && !isFrom) return swap.from.token.name;
    if (!isReverse && isFrom) return swap.from.token.name;
    if (!isReverse && !isFrom) return swap.to.name;
    return swap.from.token.name;
  }, [isReverse, isFrom, swap]);

  useEffect(() => {
    getTokensMetadata().then(
      (tokens: { name: string; address: string; icon: string | undefined }[]) =>
        setAvailableTokens(tokens)
    );
  }, []);

  const baseToken = ['tzBTC', 'BTCtz'];
  const swapsAllowed = [
    'tzBTC/USDT',
    'tzBTC/EURL',
    'BTCtz/USDT',
    'BTCtz/USDtz',
    'tzBTC/USDtz',
  ];

  const getOtherToken = () => {
    if (isReverse && isFrom) return swap.from.token.name;
    if (isReverse && !isFrom) return swap.to.name;
    if (!isReverse && isFrom) return swap.to.name;
    if (!isReverse && !isFrom) return swap.from.token.name;
    return swap.to.name;
  };

  /**
   * TODO
   * Rewrite this
   * @param token TokensNames
   * @returns (string | null) A token pair if allowed else null
   */
  const choosePair = (
    token: TokenNames
  ): { pair: string; reversed: boolean } | null => {
    const other = getOtherToken();
    //! Top selector
    if (isFrom) {
      //! chosen token is a base token
      if (baseToken.includes(token)) {
        //! user chose the same token so he want to reverse the swap
        if (token === other) {
          const t = displayValue();
          if (swapsAllowed.includes(`${token}/${t}`)) {
            return { pair: `${token}/${t}`, reversed: false };
          }
          return null;
        }
        //! chosen tokens are in allowed swaps
        if (swapsAllowed.includes(`${token}/${other}`)) {
          return { pair: `${token}/${other}`, reversed: false };
        }
        return null;
      }
      //! chosen token is NOT a base token
      if (token === other) {
        const t = displayValue();
        if (swapsAllowed.includes(`${t}/${token}`)) {
          return { pair: `${t}/${token}`, reversed: true };
        }
        return null;
      }
      if (swapsAllowed.includes(`${other}/${token}`)) {
        return { pair: `${other}/${token}`, reversed: false };
      }
      return null;
    } else {
      //! Bottom selector
      //! Chosen token is a base token
      if (baseToken.includes(token)) {
        if (token === other) {
          const t = displayValue();
          if (swapsAllowed.includes(`${t}/${other}`)) {
            return { pair: `${token}/${other}`, reversed: true };
          }
          return null;
        }
        //! chosen tokens are in allowed swaps
        if (swapsAllowed.includes(`${token}/${other}`)) {
          return { pair: `${token}/${other}`, reversed: false };
        }
        return null;
      }
      //! chosen token is NOT a base token
      if (token === other) {
        const t = displayValue();
        if (swapsAllowed.includes(`${other}/${t}`)) {
          return { pair: `${other}/${t}`, reversed: true };
        }
        return null;
      }
      if (swapsAllowed.includes(`${other}/${token}`)) {
        return { pair: `${other}/${token}`, reversed: false };
      }
      return null;
    }
  };

  return (
    <Select.Root
      value={displayValue()}
      onValueChange={value => {
        const pairChosen = choosePair(value as TokenNames);
        if (!pairChosen) dispatch(changePair('tzBTC/USDT', false));
        else {
          dispatch(changePair(pairChosen.pair, pairChosen.reversed));
        }
      }}>
      <Select.Trigger className="flex items-center text-dark w-[200px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
        <Select.Value
          placeholder={isReverse ? swap.to.name : swap.from.token.name}
        />
        <Select.Icon className="text-dark">
          <FontAwesomeIcon icon={faChevronDown} />
        </Select.Icon>
      </Select.Trigger>
      <Select.Portal className="w-[8rem]">
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
                  disabled={choosePair(t.name) === null ? true : false}>
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
          ? 'cursor-not-allowed bg-lightgray text-white'
          : 'cursor-pointer'
      } text-base text-dark rounded flex items-center h-[25px] pr-[35px] pl-[25px] relative select-none data-[highlighted]:outline-none data-[highlighted]:bg-hovergray `}
      {...props}
      ref={forwardedRef}>
      <Select.ItemText>{children}</Select.ItemText>
      <Select.ItemIndicator className="absolute left-0 w-6 inline-flex items-center justify-center">
        <FontAwesomeIcon icon={faCheck} />
      </Select.ItemIndicator>
    </Select.Item>
  );
});

export default SelectPair;
