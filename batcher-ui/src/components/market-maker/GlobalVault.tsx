import { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { useSelector } from 'react-redux';
import { getGlobalVault } from '@/actions';
import { selectCurrentVaultName, selectGlobalVault } from '@/reducers';

const GlobalVault = () => {
  const dispatch = useDispatch();

  const globalVault = useSelector(selectGlobalVault);
  const tokenName = useSelector(selectCurrentVaultName);

  useEffect(() => {
    dispatch(getGlobalVault());
  }, [dispatch]);

  //TODO
  // const showForeignAssets = (assets: Map<string, VaultToken>) => (
  //   <div>
  //     {assets.size > 0 ? (
  //       Object.values(assets).map(a => showTokenAmount({ vaultToken: a }))
  //     ) : (
  //       <div></div>
  //     )}
  //   </div>
  // );

  return (
    <div>
      <div className="flex md:flex-row flex-col">
        {globalVault && (
          <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
            <div className="p-3">
              {`Total Shares: ${globalVault.shares}`}
              <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
                <p className="text-xl text-left">Native Asset</p>
                <div className="p-3">
                  <p className="text-lg text-center">
                    {/* {vaultToken?.name} : {vaultToken?.amount} */}
                    {tokenName} : {globalVault.shares}
                  </p>
                </div>
              </div>
              <div className="p-5 border-lightgray border-t-2 border-2 border-solid justify-between md:text-base text-sm">
                <p className="text-xl text-left">Foreign Assets</p>

                {/*TODO {showForeignAssets(currentGlobalVault.foreign)} */}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default GlobalVault;
