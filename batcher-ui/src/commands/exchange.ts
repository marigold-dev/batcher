import { Cmd } from 'redux-loop';
import { getPairsInformations } from '../../utils/utils';
import { updatePairsInfos } from 'src/actions';

const fetchPairInfosCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformations(
        pair,
        process.env.REACT_APP_BATCHER_CONTRACT_HASH || ''
      );
    },
    {
      successActionCreator: updatePairsInfos,
    }
  );

export { fetchPairInfosCmd };
