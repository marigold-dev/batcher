import React, { useState, useEffect } from 'react';
import Exchange from '../components/Exchange';
import Volume from '../components/Volume';
import BatcherInfo from '../components/BatcherInfo';
import BatcherAction from '../components/BatcherAction';
import { ContentType } from '../utils/types';
import { Col, Row } from 'antd';

import Holdings from '../components/Holdings';
import About from '../components/About';
import { useSelector, useDispatch } from 'react-redux';
import { userAddressSelector } from '../src/reducers';
import {
  fetchUserBalances,
  batcherSetup,
  batcherUnsetup,
} from '../src/actions';

const Welcome = () => {
  const [content, setContent] = useState<ContentType>(ContentType.SWAP);

  const userAddress = useSelector(userAddressSelector);

  const dispatch = useDispatch();

  const [clearedHoldings, setClearedHoldings] = useState<Map<string, number>>(
    new Map<string, number>()
  );
  const [openHoldings, setOpenHoldings] = useState<Map<string, number>>(
    new Map<string, number>()
  );
  const [updateAll, setUpdateAll] = useState<boolean>(false);
  const [hasClearedHoldings /* setHasClearedHoldings */] =
    useState<boolean>(false);

  // const getOriginalDepositAmounts = (
  //   side: any,
  //   initialBuySideAmount: number,
  //   initialSellSideAmount: number,
  //   depositValue: number
  // ) => {
  //   if (Object.keys(side).at(0) === 'buy') {
  //     initialBuySideAmount +=
  //       Math.floor(depositValue) / 10 ** buyToken.decimals;
  //   } else if (Object.keys(side).at(0) === 'sell') {
  //     initialSellSideAmount +=
  //       Math.floor(depositValue) / 10 ** sellToken.decimals;
  //   } else {
  //     console.error("Couldn't understand which side the deposit was on");
  //   }
  //   return [initialBuySideAmount, initialSellSideAmount];
  // };

  // const wasInClearingForBatch = (
  //   side_obj: any,
  //   order_tolerance_obj: any,
  //   clearing_tolerance_obj: any
  // ) => {
  //   const side = Object.keys(side_obj).at(0);
  //   const order_tolerance = Object.keys(order_tolerance_obj).at(0);
  //   const clearing_tolerance = Object.keys(clearing_tolerance_obj).at(0);
  //   if (side == 'buy') {
  //     if (clearing_tolerance === 'minus') {
  //       if (order_tolerance === 'minus') {
  //         return true;
  //       } else if (order_tolerance === 'exact') {
  //         return false;
  //       } else if (order_tolerance === 'plus') {
  //         return false;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else if (clearing_tolerance === 'exact') {
  //       if (order_tolerance === 'minus') {
  //         return true;
  //       } else if (order_tolerance === 'exact') {
  //         return true;
  //       } else if (order_tolerance === 'plus') {
  //         return false;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else if (clearing_tolerance === 'plus') {
  //       if (order_tolerance === 'minus') {
  //         return true;
  //       } else if (order_tolerance === 'exact') {
  //         return true;
  //       } else if (order_tolerance === 'plus') {
  //         return true;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else {
  //       console.error('Unable to determine clearing tolerance for buy deposit');
  //     }
  //   } else if (side == 'sell') {
  //     if (clearing_tolerance === 'minus') {
  //       if (order_tolerance === 'minus') {
  //         return true;
  //       } else if (order_tolerance === 'exact') {
  //         return true;
  //       } else if (order_tolerance === 'plus') {
  //         return true;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else if (clearing_tolerance === 'exact') {
  //       if (order_tolerance === 'minus') {
  //         return false;
  //       } else if (order_tolerance === 'exact') {
  //         return true;
  //       } else if (order_tolerance === 'plus') {
  //         return true;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else if (clearing_tolerance === 'plus') {
  //       if (order_tolerance === 'minus') {
  //         return false;
  //       } else if (order_tolerance === 'exact') {
  //         return false;
  //       } else if (order_tolerance === 'plus') {
  //         return true;
  //       } else {
  //         console.error('Could not determine order tolerance for buy deposit');
  //       }
  //     } else {
  //       console.error('Unable to determine clearing tolerance for buy deposit');
  //     }
  //   } else {
  //     console.error('Unable to determine side for holdings');
  //   }
  // };

  // const convertHoldingToPayout = (
  //   fromAmount: any,
  //   fromVolumeSubjectToClearing: any,
  //   fromClearedVolume: any,
  //   toClearedVolume: any,
  //   fromDecimals: number,
  //   toDecimals: number
  // ) => {
  //   const prorata = fromAmount / fromVolumeSubjectToClearing;
  //   const payout = toClearedVolume * prorata;
  //   const payoutInFromTokens = fromClearedVolume * prorata;
  //   const remainder = fromAmount - payoutInFromTokens;
  //   const scaled_payout = Math.floor(payout) / 10 ** toDecimals;
  //   const scaled_remainder = Math.floor(remainder) / 10 ** fromDecimals;

  //   return [scaled_payout, scaled_remainder];
  // };

  // const findTokensForBatch = (batch: any) => {
  //   const pair = batch.pair;
  //   const tkns: tokens = {
  //     buy_token_name: pair.name_0,
  //     sell_token_name: pair.name_1,
  //   };
  //   return tkns;
  // };

  // const calculateHoldingFromBatch = (
  //   batch: any,
  //   ubots: any,
  //   open_holdings: Map<string, number>,
  //   cleared_holdings: Map<string, number>
  // ) => {
  //   const tkns = findTokensForBatch(batch);
  //   const depositsInBatches = ubots.value;
  //   const userBatchLength = depositsInBatches[batch.batch_number].length;

  //   if (Object.keys(batch.status)[0] !== BatcherStatus.CLEARED) {
  //     for (let j = 0; j < userBatchLength; j++) {
  //       try {
  //         const depObject = ubots.value[batch.batch_number].at(j);
  //         const side = depObject.key.side;
  //         const value = depObject.value;
  //         let initialBuySideOpenAmount =
  //           open_holdings.get(tkns.buy_token_name) || 0; // TODO: default value to 0?
  //         let initialSellSideOpenAmount =
  //           open_holdings.get(tkns.sell_token_name) || 0; // TODO: default value to 0?
  //         const updatedValues = getOriginalDepositAmounts(
  //           side,
  //           initialBuySideOpenAmount,
  //           initialSellSideOpenAmount,
  //           value
  //         );
  //         initialBuySideOpenAmount += updatedValues.at(0) || 0; // TODO: default value to 0?
  //         initialSellSideOpenAmount += updatedValues.at(1) || 0; // TODO: default value to 0?
  //         open_holdings.set(tkns.buy_token_name, initialBuySideOpenAmount);
  //         open_holdings.set(tkns.sell_token_name, initialSellSideOpenAmount);
  //       } catch (error) {
  //         console.error(error);
  //       }
  //     }
  //   } else {
  //     const cleared = batch.status.cleared;
  //     const clearing = cleared.clearing;
  //     const buy_side_cleared_volume =
  //       clearing.total_cleared_volumes.buy_side_total_cleared_volume;
  //     const sell_side_cleared_volume =
  //       clearing.total_cleared_volumes.sell_side_total_cleared_volume;
  //     const buy_side_volume_subject_to_clearing =
  //       clearing.total_cleared_volumes.buy_side_volume_subject_to_clearing;
  //     const sell_side_volume_subject_to_clearing =
  //       clearing.total_cleared_volumes.sell_side_volume_subject_to_clearing;

  //     for (let j = 0; j < userBatchLength; j++) {
  //       try {
  //         const depObject = ubots.value[batch.batch_number].at(j);
  //         const side = depObject.key.side;
  //         const tol = depObject.key.tolerance;
  //         const value = depObject.value;

  //         if (buy_side_cleared_volume === 0 || sell_side_cleared_volume === 0) {
  //           let initialBuySideAmount =
  //             cleared_holdings.get(tkns.buy_token_name) || 0; // TODO: default value to 0?
  //           let initialSellSideAmount =
  //             cleared_holdings.get(tkns.sell_token_name) || 0; // TODO: default value to 0?
  //           const updatedValues = getOriginalDepositAmounts(
  //             side,
  //             initialBuySideAmount,
  //             initialSellSideAmount,
  //             value
  //           );
  //           initialBuySideAmount += updatedValues.at(0) || 0; // TODO: default value to 0?
  //           initialSellSideAmount += updatedValues.at(1) || 0; // TODO: default value to 0?
  //           cleared_holdings.set(tkns.buy_token_name, initialBuySideAmount);
  //           cleared_holdings.set(tkns.sell_token_name, initialSellSideAmount);
  //         } else {
  //           const wasInClearing = wasInClearingForBatch(
  //             side,
  //             tol,
  //             clearing.clearing_tolerance
  //           );
  //           if (wasInClearing) {
  //             if (Object.keys(side).at(0) === 'buy') {
  //               let initialBuySideAmount =
  //                 cleared_holdings.get(tkns.buy_token_name) || 0;
  //               let initialSellSideAmount =
  //                 cleared_holdings.get(tkns.sell_token_name) || 0;
  //               const payout = convertHoldingToPayout(
  //                 value,
  //                 buy_side_volume_subject_to_clearing,
  //                 buy_side_cleared_volume,
  //                 sell_side_cleared_volume,
  //                 buyToken.decimals,
  //                 sellToken.decimals
  //               );
  //               initialSellSideAmount += payout.at(0) || 0;
  //               initialBuySideAmount += payout.at(1) || 0;
  //               cleared_holdings.set(tkns.buy_token_name, initialBuySideAmount);
  //               cleared_holdings.set(
  //                 tkns.sell_token_name,
  //                 initialSellSideAmount
  //               );
  //             } else if (Object.keys(side).at(0) === 'sell') {
  //               let initialBuySideAmount =
  //                 cleared_holdings.get(tkns.buy_token_name) || 0; // TODO: default value to 0?;
  //               let initialSellSideAmount =
  //                 cleared_holdings.get(tkns.sell_token_name) || 0; // TODO: default value to 0?;
  //               const payout = convertHoldingToPayout(
  //                 value,
  //                 sell_side_volume_subject_to_clearing,
  //                 sell_side_cleared_volume,
  //                 buy_side_cleared_volume,
  //                 sellToken.decimals,
  //                 buyToken.decimals
  //               );
  //               initialBuySideAmount += payout.at(0) || 0; // TODO: default value to 0?;
  //               initialSellSideAmount += payout.at(1) || 0; // TODO: default value to 0?;
  //               cleared_holdings.set(tkns.buy_token_name, initialBuySideAmount);
  //               cleared_holdings.set(
  //                 tkns.sell_token_name,
  //                 initialSellSideAmount
  //               );
  //             } else {
  //               console.error(
  //                 'Unable to determine side for a deposit that was in clearing'
  //               );
  //             }
  //           } else {
  //             let initialBuySideAmount =
  //               cleared_holdings.get(tkns.buy_token_name) || 0; // TODO: default value to 0?;
  //             let initialSellSideAmount =
  //               cleared_holdings.get(tkns.sell_token_name) || 0; // TODO: default value to 0?;
  //             const updatedValues = getOriginalDepositAmounts(
  //               side,
  //               initialBuySideAmount,
  //               initialSellSideAmount,
  //               value
  //             );
  //             initialBuySideAmount += updatedValues.at(0) || 0; // TODO: default value to 0?;
  //             initialSellSideAmount += updatedValues.at(1) || 0; // TODO: default value to 0?;
  //             cleared_holdings.set(tkns.buy_token_name, initialBuySideAmount);
  //             cleared_holdings.set(tkns.sell_token_name, initialSellSideAmount);
  //           }
  //         }
  //       } catch (error) {
  //         console.error(error);
  //       }
  //     }
  //   }
  //   return [open_holdings, cleared_holdings];
  // };

  // const updateHoldings = async (storage: any) => {
  //   let oh = openHoldings;
  //   let ch = clearedHoldings;
  //   try {
  //     if (!userAddress) {
  //       return;
  //     }

  //     console.info('##open holdings', openHoldings);
  //     console.info('##cleared holdings', clearedHoldings);
  //     const userBatcherURI =
  //       bigMapsByIdUri + userBatchOrderTypesBigMapId + '/keys/' + userAddress;
  //     const userOrderBookData = await fetch(userBatcherURI, { method: 'GET' });
  //     let userBatches: any = null; // TODO: need type
  //     try {
  //       userBatches = await userOrderBookData.json();
  //     } catch (error) {
  //       console.error(error);
  //       return;
  //     }

  //     if (Object.keys(userBatches.value).length === 0) {
  //       return;
  //     }

  //     for (let i = 0; i < Object.keys(userBatches.value).length; i++) {
  //       const batchId = Object.keys(userBatches.value).at(i);

  //       const batchURI =
  //         bigMapsByIdUri + storage.batch_set.batches + '/keys/' + batchId;
  //       const batchData = await fetch(batchURI, { method: 'GET' });
  //       let batch: any = null; // TODO: need type
  //       try {
  //         batch = await batchData.json();
  //       } catch (error) {
  //         console.error(error);
  //         return;
  //       }

  //       try {
  //         const batch_holdings = calculateHoldingFromBatch(
  //           batch.value,
  //           userBatches,
  //           oh,
  //           ch
  //         );

  //         console.info('== batcher holdings ' + batchId, batch_holdings);
  //         oh = batch_holdings[0];
  //         ch = batch_holdings[1];
  //       } catch (error) {
  //         console.error(error);
  //       }
  //     }
  //   } catch (error) {
  //     console.error('Unable to update holdings', error);
  //   }
  //   setOpenHoldings(oh);
  //   setClearedHoldings(ch);

  //   let sum_of_holdings = 0;
  //   for (const value of ch.values()) {
  //     sum_of_holdings = sum_of_holdings + value;
  //   }
  //   setHasClearedHoldings(sum_of_holdings > 0);
  // };

  const renderRightContent = (content: ContentType) => {
    switch (content) {
      case ContentType.SWAP:
        return <Exchange />;
      case ContentType.VOLUME:
        return <Volume />;
      case ContentType.REDEEM_HOLDING:
        return (
          <Holdings
            userAddress={userAddress}
            openHoldings={openHoldings}
            clearedHoldings={clearedHoldings}
            setOpenHoldings={setOpenHoldings}
            setClearedHoldings={setClearedHoldings}
            updateAll={updateAll}
            setUpdateAll={setUpdateAll}
            hasClearedHoldings={hasClearedHoldings}
          />
        );
      case ContentType.ABOUT:
        return <About />;
      default:
        return <Exchange />;
    }
  };

  // const updateFromStorage = async (storage: any) => {
  //   updateBigMapIds(storage);
  //   zeroHoldings(storage, setOpenHoldings, setClearedHoldings);
  //   await updateTokenDetails(storage);
  //   await getBatches(storage);
  //   await updateSwapMap(storage);
  //   await setFee(storage);
  //   await getOraclePrice();
  //   await getTokenBalance();
  //   await updateHoldings(storage);
  //   await getCurrentVolume(storage);
  // };

  useEffect(() => {
    if (userAddress) dispatch(fetchUserBalances());
  }, [userAddress, dispatch]);

  useEffect(() => {
    dispatch(batcherSetup());
    return () => {
      dispatch(batcherUnsetup());
    };
  }, [dispatch]);

  return (
    <div className="mb-auto">
      <BatcherInfo />
      <BatcherAction content={content} setContent={setContent} />

      <div>
        <Row className="batcher-content">
          <Col lg={3} />
          <Col className="batcher-content-outer" xs={24} lg={18}>
            <Row>
              <Col xs={24} lg={18} className="pd-25">
                {renderRightContent(content)}
              </Col>
            </Row>
          </Col>
        </Row>
      </div>
    </div>
  );
};

export default Welcome;
