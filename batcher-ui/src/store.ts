import {
  legacy_createStore as createStore,
  compose,
  applyMiddleware,
} from 'redux';
import { install, LoopReducer, StoreCreator } from 'redux-loop';
import { createLogger } from 'redux-logger';
import rootReducer from './reducers';
import { AppState } from './types';

const enhancedStore = createStore as StoreCreator;

const loopReducer = rootReducer as LoopReducer<AppState>;

const logger = createLogger({
  collapsed: true,
  diff: true,
});

export const store = enhancedStore(
  loopReducer,
  undefined,
  compose(install(), applyMiddleware(logger))
);

// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
