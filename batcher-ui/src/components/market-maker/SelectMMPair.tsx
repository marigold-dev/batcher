import React, { useEffect, useState } from 'react';
import * as Select from '@radix-ui/react-select';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChevronDown,
  faCheck,
  faChevronUp,
} from '@fortawesome/free-solid-svg-icons';
import { useDispatch, useSelector } from 'react-redux';
import { getMarketHoldings } from '@/actions';
import { userAddressSelector, selectCurrentVaultName } from '@/reducers';
import { getTokensMetadata } from '@/utils/token-manager';

const SelectMMPair = () => {
  const dispatch = useDispatch();

  const userAddress = useSelector(userAddressSelector);

  const currentVaultName = useSelector(selectCurrentVaultName);

  const [tokens, setTokens] = useState<
    { name: string; address: string; icon: string | undefined }[]
  >([]);

  useEffect(() => {
    getTokensMetadata().then(
      (
        tokens: { name: string; address: string; icon: string | undefined }[]
      ) => {
        setTokens(tokens);
      }
    );
  }, []);

  return (
    <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
      <span>{`Vault: `}</span>
      <Select.Root
        value={currentVaultName}
        onValueChange={value => {
          dispatch(getMarketHoldings(value, userAddress));
        }}
      >
        <Select.Trigger className="flex items-center text-dark w-[200px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
          <Select.Value placeholder={currentVaultName} />
          <Select.Icon className="text-dark">
            <FontAwesomeIcon icon={faChevronDown} />
          </Select.Icon>
        </Select.Trigger>
        <Select.Portal className="w-[7rem]">
          <Select.Content className="overflow-hidden bg-white rounded-md text-dark">
            <Select.ScrollUpButton className="flex items-center justify-center h-[25px] bg-[red] cursor-default">
              <FontAwesomeIcon icon={faChevronUp} />
            </Select.ScrollUpButton>
            <Select.Viewport className="p-2">
              <Select.Group>
                {tokens.map(t => (
                  <SelectItem value={t.name} key={t.address}>
                    {t.name}
                  </SelectItem>
                ))}
              </Select.Group>
            </Select.Viewport>
            <Select.ScrollDownButton className="flex items-center justify-center h-[25px] bg-[pink]text-violet11 cursor-default">
              <FontAwesomeIcon icon={faChevronDown} />
            </Select.ScrollDownButton>
          </Select.Content>
        </Select.Portal>
      </Select.Root>
    </div>
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
      className={`text-base text-dark rounded flex items-center h-[25px] pr-[35px] pl-[25px] relative select-none data-[highlighted]:outline-none data-[highlighted]:bg-hovergray disabled:cursor-not-allowed`}
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

export default SelectMMPair;
