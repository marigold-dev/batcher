import React, { useEffect, useState } from 'react';
import '@/components/BatcherAction/index.less';
import '@/global.less';
import type { DrawerProps, RadioChangeEvent } from 'antd';
import { Button, Col, Space, Row, Typography, Drawer, Radio, } from 'antd';
import { BatcherActionProps, ContentType, token, swap } from '@/extra_utils/types';

const { Text } = Typography;

const BatcherAction: React.FC<BatcherActionProps> = ({
  setContent,
  tezos,
  tokenMap,
  setBuyTokenName,
  setBuyTokenAddress,
  setBuyTokenDecimals,
  setBuyTokenStandard,
  setSellTokenName,
  setSellTokenAddress,
  setSellTokenDecimals,
  setSellTokenStandard,
  tokenPair,
  setTokenPair,
  }: BatcherActionProps) => {
  const [open, setOpen] = useState(false);
  const [swaps, setSwaps] = useState<string[]>([]);
  const showDrawer = () => {
    setOpen(true);
  };

  const onClose = () => {
    setOpen(false);
  };



  const getPairs = () => {
    let swps = [];
     console.log('swap_map', tokenMap);
     for (let keyvalue of tokenMap)  {
         console.log(keyvalue);
         swps.push(keyvalue[0]);
     }
    setSwaps(swps);
    console.log('swps', swps);
    console.log('swaps', swaps);
  };

 const changeTokenPair =  (e: RadioChangeEvent) => {
    const pair = e.target.value;
    console.log('pair changed', pair);
    setTokenPair(pair);
    let swap = tokenMap.get(pair);
    console.log('pair changed to ', swap);


    // Set Buy Token Details
    setBuyTokenName(swap.from.token.name);
    setBuyTokenAddress(swap.from.token.address);
    setBuyTokenDecimals(swap.from.token.decimals);
    setBuyTokenStandard(swap.from.token.standard);

    // Set Sell Token Details
    setSellTokenName(swap.to.name);
    setSellTokenAddress(swap.to.address);
    setSellTokenDecimals(swap.to.decimals);
    setSellTokenStandard(swap.to.standard);

 };

  const generatePairs = () => {
      return (
            <>
            {
            swaps.map((swap) =>
                <React.Fragment key={swap}>
                       <Radio.Button className="batcher-nav-btn" value={swap} onChange={changeTokenPair} >{swap}</Radio.Button>
                </React.Fragment>
            )}
        </>
    );


  };


  useEffect(() => {
    getPairs();
  }, [tokenMap]);


  const containerStyle: React.CSSProperties = {
    position: 'relative',
    height: 200,
    padding: 48,
    overflow: 'hidden',
    textAlign: 'center',
  };


  return (
    <div>
      <Row>
        <Col lg={3} />
        <Col lg={18} xs={24}>
          <Row className="batcher-action-outer">
            <Col lg={3} />
            <Col className="batcher-action-items" lg={18} xs={24}>
              <Space align="center">
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.SWAP)}>
                  <Text underline>Swap</Text>
                </Button>
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.VOLUME)}>
                  <Text underline>Volume</Text>
                </Button>
                <Button
                  className="batcher-nav-btn"
                  onClick={() => setContent(ContentType.REDEEM_HOLDING)}
                >
                  <Text underline>Redeem Holdings</Text>
                </Button>
                <Button
                  className="batcher-nav-btn"
                  onClick={showDrawer}
                >
                  <Text underline>Change Pair</Text>
                </Button>
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.ABOUT)}>
                  <Text underline>About</Text>
                </Button>
                  <Drawer
                   title="Available Pairs"
                   placement="right"
                   onClose={onClose}
                   open={open}
                   closable={false}
                   width="10%"
                  >
                  <Radio.Group defaultValue={tokenPair} buttonStyle="solid">
                   <Space direction="vertical">
                    {
                      generatePairs()
                    }
                    </Space>
                  </Radio.Group>
                  </Drawer>
              </Space>
            </Col>
            <Col lg={3} />
          </Row>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default BatcherAction;
