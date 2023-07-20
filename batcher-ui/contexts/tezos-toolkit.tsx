import { TezosToolkit } from '@taquito/taquito';
import React, { createContext, useEffect, useState } from 'react';

type TzTkState = {
  connection: TezosToolkit;
};

export const TezosToolkitContext = createContext<TzTkState>({
  connection: undefined,
});

export const TezosToolkitProvider = ({ children }) => {
  const [connection, setConnection] = useState<TezosToolkit>();
  useEffect(() => {
    if (process.env.REACT_APP_TEZOS_NODE_URI) {
      setConnection(new TezosToolkit(process.env.REACT_APP_TEZOS_NODE_URI));
    }
  }, []);

  return (
    <TezosToolkitContext.Provider value={{ connection }}>{children}</TezosToolkitContext.Provider>
  );
};
