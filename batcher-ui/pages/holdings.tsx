import React, { useCallback, useContext, useEffect } from 'react';
import { TezosToolkitContext } from 'src/contexts/tezos-toolkit';
import { useDispatch, useSelector } from 'react-redux';
import { getHoldings, userAddressSelector } from 'src/reducers';
import { getHoldings as getHoldingsAction } from 'src/actions';

const Holdings = () => {
  const { tezos } = useContext(TezosToolkitContext);
  const contractAddress = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  const { open, cleared } = useSelector(getHoldings);
  const userAddress = useSelector(userAddressSelector);

  const dispatch = useDispatch();

  const hasClearedHoldings = useCallback(
    () => Object.values(cleared).some(holdings => holdings > 0),
    [cleared]
  );

  useEffect(() => {
    if (userAddress) {
      dispatch(getHoldingsAction(userAddress));
    }
  }, [userAddress, dispatch]);

  const redeem = async (): Promise<void> => {
    try {
      if (!tezos || !contractAddress) {
        throw new Error('Failed to initialize communication with contract.');
      }
      const contractWallet = await tezos.wallet.at(contractAddress);

      let redeemTransaction = await contractWallet.methods.redeem().send();

      if (redeemTransaction) {
        //?useless
        // message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeemTransaction.confirmation();
        if (!confirm.completed) {
          console.error('Failed to redeem holdings' + confirm);
        } else {
          // setOpenHoldings(new Map<string, number>());
          // setClearedHoldings(new Map<string, number>());
          console.info('Successfully redeemed holdings');
        }
      } else {
        throw new Error('Failed to redeem tokens');
      }
    } catch (error: any) {
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
                key={i}>
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
                  className="border border-white p-2 text-center bg-lightgray"
                  key={i}>
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
                key={i}>
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
                  className="border border-white p-2 text-center bg-lightgray"
                  key={i}>
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
            className="text-white bg-primary rounded py-2 px-4 m-2 hidden md:flex hover:bg-red-500"
            type="button"
            onClick={redeem}>
            Redeem
          </button>
        )}
      </>
    </div>
  );
};

export default Holdings;
