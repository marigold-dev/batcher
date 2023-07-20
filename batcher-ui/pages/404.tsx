import { Result } from 'antd';
import React from 'react';
import Link from 'next/link';

const NoFoundPage: React.FC = () => (
  <Result
    status="404"
    title="404"
    subTitle="Sorry, the page you visited does not exist."
    extra={
      <Link type="button" href={{ pathname: '/' }}>
        Back Home
      </Link>
    }
  />
);

export default NoFoundPage;
