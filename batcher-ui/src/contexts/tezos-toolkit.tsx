import { TezosToolkit } from '@taquito/taquito';
import React, { createContext } from 'react';

type TzTkState = {
  tezos: TezosToolkit;
};

export const TezosToolkitContext = createContext<TzTkState>({
  tezos: new TezosToolkit(process.env.NEXT_PUBLIC_TEZOS_NODE_URI || ''),
});

export const useTezosToolkit = () => React.useContext(TezosToolkitContext);

export const TezosToolkitProvider = ({ children }: { children: React.ReactNode }) => {
  const { tezos } = useTezosToolkit();
  return (
    <TezosToolkitContext.Provider value={{ tezos }}>
      {children}
    </TezosToolkitContext.Provider>
  );
};
