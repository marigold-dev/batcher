import React, { useEffect, useState } from 'react';
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

const SelectPair = () => {
  const { swap, isReverse } = useSelector(currentSwapSelector);
  const dispatch = useDispatch();

  const [availableTokens, setAvailableTokens] = useState<any[]>([]);

  useEffect(() => {
    getTokensMetadata().then(
      (tokens: { name: string; address: string; icon: string | undefined }[]) =>
        setAvailableTokens(tokens)
    );
  }, []);

  return (
    <Select.Root
      // value={availableTokens[1].name}
      value={isReverse ? swap.to.name : swap.from.token.name}
      onValueChange={value => {
        //TODO: change this when we had more pair
        // const parsedValue = value === 'USDt'
        const pair =
          value === 'tzBTC' ? `tzBTC/${swap.to.name}` : `tzBTC/${value}`;
        const reversed = value !== 'tzBTC';
        dispatch(changePair(pair, reversed));
      }}>
      <Select.Trigger className="flex items-center text-dark w-[140px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
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
                  }>
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
                        alt={`${t.name} icon`}
                        width={24}
                        height={24}
                        style={{ paddingRight: 4 }}
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
      ref={forwardedRef}>
      <Select.ItemText>{children}</Select.ItemText>
      <Select.ItemIndicator className="absolute left-0 w-6 inline-flex items-center justify-center">
        <FontAwesomeIcon icon={faCheck} />
      </Select.ItemIndicator>
    </Select.Item>
  );
});

export default SelectPair;
