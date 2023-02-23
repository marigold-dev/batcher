import React, { useEffect, useState } from 'react';
import '@/components/BatcherAction/index.less';
import '@/global.less';
import type {  RadioChangeEvent } from 'antd';
import { Button, Col, Space, Row, Typography, Drawer, Radio, } from 'antd';
import { BatcherActionProps, ContentType } from '@/extra_utils/types';

const { Text } = Typography;

const BatcherAction: React.FC<BatcherActionProps> = ({
  setContent,
  tokenMap,
  setBuyToken,
  setSellToken,
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
    const swps = [];
     console.log('swap_map', tokenMap);
     for (const keyvalue of tokenMap)  {
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
    const swap = tokenMap.get(pair);
    console.log('pair changed to ', swap);
    // Set Buy Token Details
    setBuyToken(swap.from.token);

    // Set Sell Token Details
    setSellToken(swap.to);

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
