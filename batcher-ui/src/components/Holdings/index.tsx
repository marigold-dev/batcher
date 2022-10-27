import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, message } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { HoldingsProps, batch, token_amount } from '@/extra_utils/types';
import { scaleAmountDown } from '@/extra_utils/utils';
import { JSONPath } from "jsonpath-plus";
import toast from "react-hot-toast";
import MarigoldLogoSvg from '../../../img/marigold-logo.svg';

const { Text } = Typography;

const Holdings: React.FC<HoldingsProps> = ({tezos, bigMapsByIdUri,userAddress, contractAddress, previousTreasuries, buyToken, sellToken }: HoldingsProps) => {
  const [inversion, setInversion] = useState(true);
  const { initialState } = useModel('@@initialState');

  const [buyTokenHoldings, setBuyTokenHoldings] = useState<number>(0);
  const [sellTokenHoldings, setSellTokenHoldings] = useState<number>(0);

  const update_holdings = async () => {
    console.log('Holdings-previousBatches',previousTreasuries);
    let buy_holdings = 0;
    let sell_holdings = 0;

    setBuyTokenHoldings(buy_holdings);
    setSellTokenHoldings(sell_holdings);

    for(var i =0; i < previousTreasuries?.length; i++) {
     try{
       let bm_uri = bigMapsByIdUri + previousTreasuries.at(i) + "/keys/" + userAddress;
       console.log('Holdings-bm-uri',bm_uri);
       const data = await fetch(bm_uri, {
          method: "GET"
       });
       const jsonData = await data.json();

       if(!jsonData.active) {
          break;
       }

       const amounts = JSONPath({ path: "$.value.*.token_amount", json:jsonData});
       const tokenAmounts = amounts as Array<token_amount>;

       buy_holdings = tokenAmounts.reduce((prev, token_amount) => {
        if (token_amount.token.name === buyToken.name){
          prev += scaleAmountDown(token_amount.amount, buyToken.decimals);
        }
        return prev;
       },0);

       sell_holdings = tokenAmounts.reduce((prev, token_amount) => {
        if (token_amount.token.name === sellToken.name){
          prev += scaleAmountDown(token_amount.amount, sellToken.decimals);
        }
        return prev;
       },0);

       setBuyTokenHoldings(buy_holdings);
       setSellTokenHoldings(sell_holdings);

      } catch (error : any) {
        console.log(error);
      }
    }
  };

  const redeemHoldings = async () : Promise<void> => {
    console.log("redeeming");
    message.loading("Attempting to redeem holdings...");
     try{
        const contractWallet = await tezos.wallet.at(contractAddress);
        const buyTokenWalletContract = await tezos.wallet.at(buyToken.address);
        const sellTokenWalletContract = await tezos.wallet.at(sellToken.address);

        const operator_params = [
         {
            remove_operator : {
              owner: userAddress,
              operator: contractAddress,
              token_id: 0
            }
         }
        ];

        const redeem_op = await tezos.wallet.batch()
           .withContractCall(contractWallet.methodsObject.redeem())
           .withContractCall(buyTokenWalletContract.methods.update_operators(operator_params))
           .withContractCall(sellTokenWalletContract.methods.update_operators(operator_params))
           .send();

        const confirm = await redeem_op.confirmation();
        if(!confirm.completed){
           message.error("Failed to redeem holdings");
           console.error("Failed to redeem holdings" + confirm);
        } else {
           message.success("Successfully redeemed holdings");
        }
     } catch (error:any){
           message.error("Unable to redeem holdings : " + error.message);
           console.error("Unable to redeem holdings" + error);
     }
  };

  useEffect(() => {
   (async () => update_holdings())();
  }, [initialState,userAddress]);


  return (
              <Col className="base-content br-t br-b br-l br-r">
                <Space className="batcher-price" direction="vertical">
                  <Row>
                    <Col className="mr-c" span={5}>
                      <Typography className="batcher-title p-16">
                       Holdings
                      </Typography>
                    </Col>
                  </Row>
                      <Row className="text-center">
                    <Col className="batcher-title br-t br-b" span={8} offset={8}>
                        <Space  direction="vertical">
                       <Typography className="p-12" autosize>{buyTokenHoldings} {buyToken.name}</Typography>
                       </Space>
                       </Col>
                       </Row>
                      <Row className="text-center">
                    <Col className="batcher-title br-t br-b" span={8} offset={8}>
                        <Space  direction="vertical">
                       <Typography className="p-12">{sellTokenHoldings} {sellToken.name}</Typography>
                       </Space>
                       </Col>
                      </Row>
                      <Row className="text-center">
                    <Col span={8} offset={8}>
                      <Button className="mtb-25" type="primary" onClick={redeemHoldings} danger>
                         Redeem
                      </Button>
                       </Col>
                    </Row>
                    </Space>
              </Col>
  );
};

export default Holdings;
