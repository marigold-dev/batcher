import React, { useContext } from 'react';
import { Button, Space, Col, message } from 'antd';
import { HoldingsProps } from '../../utils/types';
import { TezosToolkitContext } from '../../contexts/tezos-toolkit';
const Holdings: React.FC<HoldingsProps> = ({
  openHoldings,
  clearedHoldings,
  setOpenHoldings,
  setClearedHoldings,
  updateAll,
  setUpdateAll,
  hasClearedHoldings,
}: HoldingsProps) => {
  const { tezos } = useContext(TezosToolkitContext);

  const contractAddress = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  const triggerUpdate = () => {
    setTimeout(function () {
      const u = !updateAll;
      setUpdateAll(u);
    }, 5000);
  };

  // const generateHoldings = (dict: Map<string, number>) => {
  //   const data: { token: string; holding: number }[] = [];

  //   for (const key of dict) {
  //     data.push({
  //       token: key[0],
  //       holding: key[1],
  //     });
  //   }
  //   return (
  //     <>
  //       {data.map(h => (
  //         <React.Fragment key={h.token}>
  //           <Typography>
  //             {' '}
  //             {h.holding} {h.token} |{' '}
  //           </Typography>
  //         </React.Fragment>
  //       ))}
  //     </>
  //   );
  // };

  const redeemHoldings = async (): Promise<void> => {
    try {
      if (!tezos || !contractAddress) {
        throw new Error('Failed to initialize communication with contract.');
      }
      // TODO: connect wallet
      // connection.setWalletProvider(state.wallet);
      const contractWallet = await tezos.wallet.at(contractAddress);
      let redeem_op = await contractWallet.methods.redeem().send();

      if (redeem_op) {
        message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeem_op.confirmation();
        if (!confirm.completed) {
          message.error('Failed to redeem holdings');
          console.error('Failed to redeem holdings' + confirm);
        } else {
          setOpenHoldings(new Map<string, number>());
          setClearedHoldings(new Map<string, number>());
          message.loading('Attempting to redeem holdings...', 0);
          message.success('Successfully redeemed holdings');
          triggerUpdate();
        }
      } else {
        throw new Error('Failed to redeem tokens');
      }
    } catch (error: any) {
      // loading();
      message.error('Unable to redeem holdings : ' + error.message);
      console.error('Unable to redeem holdings' + error);
    }
  };

  const mockGenerateHoldings = () => ' | 0 EURL | 0 USDT |0 tzBTC | ';
  return (
    <div className="font-custom flex flex-col border-solid border-2 border-#7B7B7E max-w-screen-md">
      <div className="flex flex-col p-6">
        <p className="p-4">Open/Closed Batches</p>
        <div className="bg-[#2B2A2E] flex flex-row border-2 border-solid border-lightgray p-6">
          <p>Holdings =&gt; </p>
          {/* {generateHoldings(openHoldings)} */}
          <p>{mockGenerateHoldings()}</p>
        </div>
      </div>
      <div className="flex flex-col p-6">
        <p className="p-4">Cleared Batches (Redeemable)</p>
        <div className="flex flex-col">
          <div className="bg-[#2B2A2E] flex flex-row border-2 border-solid border-lightgray p-6">
            <p>Holdings =&gt; </p>
            {/* {generateHoldings(clearedHoldings)} */}
            <p>{mockGenerateHoldings()}</p>
          </div>
        </div>
      </div>
      <Space className="batcher-price" direction="vertical">
        <Col className="batcher-redeem-btn">
          {hasClearedHoldings ? (
            <Button
              className="btn-content mtb-25"
              type="primary"
              onClick={redeemHoldings}
              danger>
              Redeem
            </Button>
          ) : (
            <div></div>
          )}
        </Col>
      </Space>
    </div>
  );
};

export default Holdings;
