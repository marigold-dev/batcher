import React from 'react';
import Link from 'next/link';

const About = () => {
  return (
    <div className="flex flex-col items-center border-solid border-2 border-lightgray py-4 md:mx-[15%] mx-8 my-4 p-2 md:text-base text-sm">
      <h2 className="border-solid border-2 border-lightgray p-2">
        WHAT IS BATCHER?
      </h2>

      <p className="m-4">
        Batcher is a new type of DEX that we have named a batch clearing DEX. It
        provides a dark pool-like trading environment without using liquidity
        pools or having the issue of significant slippage. Batcher’s goal is to
        enable users to deposit tokens with the aim of being swapped at a
        <i>fair price</i> with
        <i>bounded slippage</i> and almost no <i>impermanent loss</i>. This
        means that all orders for potential swaps between two pairs of tokens
        are collected over a finite period (currently 10 minutes). This is
        deemed the batch. After the order collection period is over, the batch
        is closed to additions. Batcher then waits for the next Oracle price for
        the token pair. When this is received, the batch is terminated and then
        Batcher looks to match the maximum amount of orders at the fairest
        possible price.
      </p>

      <h2 className="border-solid border-2 border-lightgray p-2">TIMELINE</h2>

      <p className="m-4">
        For V1, the <i>deposit window</i> will be 10 mins and then a wait time
        of 2 minutes before awaiting the oracle price. Once we got oracle price,
        the batch is cleared.
      </p>

      <h2 className="border-solid border-2 border-lightgray p-2">DISCLAIMER</h2>
      <p className="m-4">
        <i>
          All investing comes with risk and DeFi is no exception. The content in
          this Dapp contains no financial advice. Please do your own thorough
          research and note that all users funds are traded at their own risk.
          No reimbursement will be made and Marigold will not assume
          responsibility for any losses.
        </i>
      </p>

      <h2 className="border-solid border-2 border-lightgray p-2">NOTE</h2>

      <p className="m-4">
        Batcher can deal with token value imbalance which means that holders of{' '}
        <i>tzBTC</i>
        and holders of <i>USDT</i> can swap different amounts as long as there
        is a market for the
        <i>trade</i> on both sides.
      </p>

      <p className="m-4">
        Batcher has been designed to be composable with other high liquidity
        paths in the Tezos ecosystem, specifically the Sirius DEX; thus, the two
        pairs that are supported in V1 are tzBTC/USDT and tzBTC/EURL.
      </p>
      <p className="m-4">
        For more information including blog posts and faqs, please visit the
        Batcher project page at Marigold.dev.
      </p>
      <Link
        href="https://www.marigold.dev/batcher"
        target="_blank"
        className={
          'bg-primary hover:bg-lightgray hover:text-white block rounded-md px-3 py-2 text-base font-medium text-white md:text-sm my-4'
        }
        aria-current="page">
        {'Batcher Project Page'}
      </Link>
    </div>
  );
};

export default About;
