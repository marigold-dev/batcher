import React from 'react';
import { PriceStrategy } from 'src/types';
import { volumesSelector } from 'src/reducers';
import { useSelector } from 'react-redux';
// import '../Exchange/index.less';
// import './index.less';
// import '../../src/global.less';
// import { VolumeProps } from '../../utils/types';

const Volume = () => {
  const { sell, buy } = useSelector(volumesSelector);

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
    <div className="flex flex-col items-center">
      <p className="my-8">VOLUMES</p>
      <table className="border-collapse border border-slate-500">
        <thead>
          <tr>
            {listOfBuyVolumesColumns.map((b, i) => (
              <th
                className="border border-slate-500 p-2 text-center bg-slate-900"
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
                  className="border border-slate-700 p-2 text-center bg-slate-400"
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
                className="border border-slate-500 p-2 text-center bg-slate-900"
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
                  className="border border-slate-700 p-2 text-center bg-slate-400"
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
