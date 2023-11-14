import React, { useCallback, useContext, useEffect } from 'react';
import { TezosToolkitContext } from '@/contexts/tezos-toolkit';
import { useDispatch, useSelector } from 'react-redux';
import { getHoldings, userAddressSelector, tokensSelector } from '@/reducers';
import { getHoldings as getHoldingsAction, newError, newInfo } from '@/actions';

const Holdings = () => {
  const { tezos } = useContext(TezosToolkitContext);
  const contractAddress = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;
  const tokens = useSelector(tokensSelector);
  const { open, cleared } = useSelector(getHoldings);
  const userAddress = useSelector(userAddressSelector);
 console.info("TOKENS", tokens);
  const dispatch = useDispatch();

  const hasClearedHoldings = useCallback(
    () => Object.values(cleared).some(holdings => holdings > 0),
    [cleared]
  );

  useEffect(() => {
    if (userAddress) {
      dispatch(getHoldingsAction(userAddress, tokens));
    }
  }, [userAddress, dispatch, tokens]);

  const redeem = async (): Promise<void> => {
    try {
      if (!tezos || !contractAddress) {
        throw new Error('Failed to initialize communication with contract.');
      }
      const contractWallet = await tezos.wallet.at(contractAddress);

      let redeemTransaction = await contractWallet.methods.redeem().send();

      if (redeemTransaction) {
        //?useless
        dispatch(newInfo('Attempting to redeem holdings...'));
        // message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeemTransaction.confirmation();
        if (!confirm || !confirm.completed) {
          dispatch(newError('Failed to redeem holdings.'));
        } else {
          dispatch(newInfo('Successfully redeemed holdings.'));
        }
      } else {
        dispatch(newError('Failed to redeem tokens.'));
        throw new Error('Failed to redeem tokens');
      }
    } catch (error) {
      dispatch(newError('Unable to redeem holdings.'));
      console.error('Unable to redeem holdings' + error);
    }
  };
  return (
    <div className="flex flex-col items-center border-solid border-2 border-lightgray py-4 md:mx-[15%] mx-8 mt-4">
      <p className="mb-8 text-xl">Holdings</p>
      <p>Open/closed batches</p>
      <table className="border-collapse md:text-base text-sm md:my-8 my-4 min-w-[50%]">
        <thead>
          <tr>
            {Object.keys(open).map((b, i) => (
              <th
                className="border border-white p-2 text-center bg-darkgray"
                key={i}
              >
                {b}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          <tr>
            {Object.values(open).map((b, i) => {
              return (
                <td
                  className="border border-white p-2 text-center bg-lightgray w-[33%]"
                  key={i}
                >
                  {b}
                </td>
              );
            })}
          </tr>
        </tbody>
      </table>

      <p>Cleared batches (Redeemable)</p>

      <table className="border-collapse md:text-base text-sm md:my-8 my-4 min-w-[50%]">
        <thead>
          <tr>
            {Object.keys(cleared).map((b, i) => (
              <th
                className="border border-white p-2 text-center bg-darkgray"
                key={i}
              >
                {b}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          <tr>
            {Object.values(cleared).map((b, i) => {
              return (
                <td
                  className="border border-white p-2 text-center bg-lightgray w-[33%]"
                  key={i}
                >
                  {b}
                </td>
              );
            })}
          </tr>
        </tbody>
      </table>
      <>
        {hasClearedHoldings() && (
          <button
            className="text-white bg-primary rounded py-2 px-4 m-2 md:flex hover:bg-red-500"
            type="button"
            onClick={redeem}
          >
            Redeem
          </button>
        )}
      </>
    </div>
  );
};

export default Holdings;
