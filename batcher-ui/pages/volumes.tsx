import React, { useEffect } from 'react';
import { PriceStrategy } from 'src/types';
import { volumesSelector } from 'src/reducers';
import { useSelector } from 'react-redux';
import { useDispatch } from 'react-redux';
import { getCurrentBatchNumber } from 'src/actions';

const Volume = () => {
  const { sell, buy } = useSelector(volumesSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(getCurrentBatchNumber());
  }, [dispatch]);

  const listOfBuyVolumesColumns = [
    {
      title: 'Buy Minus Volume',
      key: PriceStrategy.WORSE,
      dataIndex: 'buyMinusVolume',
    },
    {
      title: 'Buy Exact Volume',
      key: PriceStrategy.EXACT,
      dataIndex: 'buyExactVolume',
    },
    {
      title: 'Buy Plus Volume',
      key: PriceStrategy.BETTER,
      dataIndex: 'buyPlusVolume',
    },
  ];

  const listOfSellVolumesColumns = [
    {
      title: 'Sell Minus Volume',
      key: PriceStrategy.WORSE,
      dataIndex: 'sellMinusVolume',
    },
    {
      title: 'Sell Exact Volume',
      key: PriceStrategy.EXACT,
      dataIndex: 'sellExactVolume',
    },
    {
      title: 'Sell Plus Volume',
      key: PriceStrategy.BETTER,
      dataIndex: 'sellPlusVolume',
    },
  ];
  return (
    <div className="flex flex-col items-center border-solid border-2 border-lightgray py-4 md:mx-[15%] mx-8 mt-4">
      <p className="mb-4 text-xl">Volumes</p>
      <table className="border-collapse md:m-0 mx-4 md:text-base text-sm">
        <thead>
          <tr>
            {listOfBuyVolumesColumns.map((b, i) => (
              <th
                className="border border-white p-2 text-center bg-darkgray"
                key={i}>
                {b.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          <tr>
            {listOfBuyVolumesColumns.map((b, i) => {
              return (
                <td
                  className="border border-white p-2 text-center bg-lightgray"
                  key={i}>
                  {buy[b.key]}
                </td>
              );
            })}
          </tr>
        </tbody>
        <thead>
          <tr>
            {listOfSellVolumesColumns.map((b, i) => (
              <th
                className="border border-white p-2 text-center bg-darkgray"
                key={i}>
                {b.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          <tr>
            {listOfSellVolumesColumns.map((b, i) => {
              return (
                <td
                  className="border border-white p-2 text-center bg-lightgray"
                  key={i}>
                  {sell[b.key]}
                </td>
              );
            })}
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default Volume;
