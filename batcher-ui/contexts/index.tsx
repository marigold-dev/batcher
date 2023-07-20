import React, { Dispatch, createContext, useReducer } from 'react';
import { WalletProvider } from '@taquito/taquito';

// Types

type AppState = {
  wallet: WalletProvider | undefined;
  userAddress: string | undefined;
  userAccount: unknown | null;
  settings: null;
};

// -------------- //

const initialState = {
  wallet: undefined,
  userAddress: undefined,
  userAccount: null,
  settings: null,
};

export const AppStateContext = createContext<AppState>(initialState);
export const AppDispatchContext = createContext<Dispatch<{}>>(() => {});

export const reducer = (state: AppState, action: unknown): AppState => {
  return {
    wallet: undefined,
    userAddress: undefined,
    userAccount: null,
    settings: null,
  };
};

export const AppProvider = ({ children }) => {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <AppStateContext.Provider value={state}>
      <AppDispatchContext.Provider value={dispatch}>{children}</AppDispatchContext.Provider>
    </AppStateContext.Provider>
  );
};
