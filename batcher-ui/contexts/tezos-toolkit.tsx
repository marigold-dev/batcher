import { TezosToolkit } from '@taquito/taquito';
import React, { createContext, useEffect, useState } from 'react';

type TzTkState = {
  tezos?: TezosToolkit;
};

export const TezosToolkitContext = createContext<TzTkState>({
  tezos: undefined,
});

export const TezosToolkitProvider = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  const [tezos, setConnection] = useState<TezosToolkit>();
  useEffect(() => {
    if (process.env.REACT_APP_TEZOS_NODE_URI) {
      setConnection(new TezosToolkit(process.env.REACT_APP_TEZOS_NODE_URI));
    }
  }, []);

  return (
    <TezosToolkitContext.Provider value={{ tezos }}>
      {children}
    </TezosToolkitContext.Provider>
  );
};

export const useTezosToolkit = () => React.useContext(TezosToolkitContext);