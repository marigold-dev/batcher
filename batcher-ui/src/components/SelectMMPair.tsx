import React from 'react';
import * as Select from '@radix-ui/react-select';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faChevronDown,
  faCheck,
  faChevronUp,
} from '@fortawesome/free-solid-svg-icons';
import { MVault } from 'src/types';
import { useDispatch } from 'react-redux';
import { changeVault } from 'src/actions';
import { getMVault } from 'src/utils/utils';

const getTokens = (vaults: Map<string, MVault> | undefined) => {
  return !vaults ? [] : Array.from(vaults.keys());
};

interface SelectMMPairProps {
  vaults: Map<string, MVault>;
  current_vault: MVault;
}
const SelectMMPair = ({ vaults, current_vault }: SelectMMPairProps) => {
  const dispatch = useDispatch();

  return (
    <Select.Root
      value={getMVault(current_vault).global.native.name}
      onValueChange={value => {
        console.warn(value);
        dispatch(changeVault(value));
      }}
    >
      <Select.Trigger className="flex items-center text-dark w-[90px] justify-center rounded px-2 mr-1 text-base gap-2 bg-white hover:bg-hovergray outline-none">
        <Select.Value
          placeholder={getMVault(current_vault).global.native.name}
        />
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
              {getTokens(vaults).map((t: string) => (
                <SelectItem value={t} key={t}>
                  {t}
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
