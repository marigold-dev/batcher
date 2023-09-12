import React, { useCallback, useContext, useEffect } from 'react';
import { TezosToolkitContext } from 'src/contexts/tezos-toolkit';
import { useDispatch, useSelector } from 'react-redux';
import { getMarketHoldings, userAddressSelector } from 'src/reducers';
import { getMarketHoldings as getMarketHoldingsAction } from 'src/actions';

const Holdings = () => {
  const { tezos } = useContext(TezosToolkitContext);
  const contractAddress = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  const { vaults } = useSelector(getMarketHoldings);
  const userAddress = useSelector(userAddressSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    if (userAddress) {
      dispatch(getMarketHoldingsAction(userAddress));
    }
  }, [userAddress, dispatch]);

  return (
    <div className="flex flex-col items-center border-solid border-2 border-lightgray py-4 md:mx-[15%] mx-8 mt-4">
      <p className="mb-8 text-xl">Market Vaults</p>
      <p>Total</p>
      <table className="border-collapse md:text-base text-sm md:my-8 my-4 min-w-[50%]">
        <thead>
          <tr>
            {Object.keys(vaults).map((b, i) => (
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
            {Object.values(vaults).map((b, i) => {
              return (
                <td
                  className="border border-white p-2 text-center bg-lightgray"
                  key={i}
                >
                  {b.total_shares}
                </td>
              );
            })}
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default Holdings;
