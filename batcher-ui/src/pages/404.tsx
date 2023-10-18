import React from 'react';
import Link from 'next/link';
import Head from 'next/head';

const NoFoundPage = () => (
  <>
    <Head>
      <title>BATCHER - Not found</title>
    </Head>
    <div className="flex flex-col items-center">
      <p>Sorry, the page you visited does not exist</p>

      <Link
        className="bg-primary rounded p-4 mt-4"
        type="button"
        href={{ pathname: '/' }}>
        Back Home
      </Link>
    </div>
  </>
);

export default NoFoundPage;
