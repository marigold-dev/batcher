import { TezosToolkit } from '@taquito/taquito';
import { Cmd } from 'redux-loop';
import { tezosToolkitSetuped } from 'src/actions';

export const setupTezosToolkitCmd = () => {
  return Cmd.run(
    () => {
      const tezosNodeUri = process.env.REACT_APP_TEZOS_NODE_URI;
      if (!tezosNodeUri) return null;
      const tezos = new TezosToolkit(tezosNodeUri);
      return tezos;
    },
    {
      successActionCreator: tezos => tezosToolkitSetuped(tezos),
    }
  );
};
