import React from 'react';
import Link from "next/link";

const About = () => {
  return (
    <div className="font-custom flex flex-col max-w-[75%] justify-center items-center">
      <p>
        Batcher is a new type of DEX that we have named a batch clearing DEX. It
        provides a dark pool-like trading environment without using liquidity
        pools or having the issue of significant slippage. Batcher’s goal is to
        enable users to deposit tokens with the aim of being swapped at a{' '}
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

      <p>
        For V1, the <i>deposit window</i> will be 10 mins and then a wait time
        of 2 minutes before awaiting the oracle price.
      </p>

      <p>
        Note: Batcher can deal with token value imbalance which means that
        holders of <i>tzBTC</i>
        and holders of <i>USDT</i> can swap different amounts as long as there
        is a market for the
        <i>trade</i> on both sides.
      </p>

      <p>
        Batcher has been designed to be composable with other high liquidity
        paths in the Tezos ecosystem, specifically the Sirius DEX; thus, the two
        pairs that are supported in V1 are tzBTC/USDT and tzBTC/EURL.
      </p>
      <p>
        For more information including blog posts and faqs, please visit the
        Batcher project page at Marigold.dev.
        <Link
          href="https://www.marigold.dev/batcher"
          title="Batcher Project Page"
        />
      </p>
      <p>
        <i> *DISCLAIMER:*</i>
        <i>
          All investing comes with risk and DeFi is no exception. The content in
          this Dapp contains no financial advice. Please do your own thorough
          research and note that all users funds are traded at their own risk.
          No reimbursement will be made and Marigold will not assume
          responsibility for any losses.
        </i>
      </p>
    </div>
  );
};

export default About;
