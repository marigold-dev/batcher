import { TwitterOutlined, GithubOutlined } from '@ant-design/icons';
import { FooterToolbar } from '@ant-design/pro-components';
import { Space } from 'antd';
import React from 'react';
import Image from 'next/image';
import MarigoldLogo from '../../img/marigold-logo.png';

const Footer: React.FC = () => {
  const LeftFooter = (
    <a href="https://www.marigold.dev/">
      <Space>
        <h1 style={{ marginBottom: '0', fontSize: '16px', color: '#FFFFFF' }}>MARIGOLD</h1>
        <Image
          alt="Marigold Logo"
          src="https://stickerdeco.fr/wp-content/uploads/2018/08/zelda_wind-waker_link-03.jpg"
        />
      </Space>
    </a>
  );

  return (
    <FooterToolbar extra={LeftFooter}>
      <Space>
        <a href="https://twitter.com/Marigold_Dev">
          <TwitterOutlined style={{ color: '#FFFFFF' }} />
        </a>
        <a href="https://github.com/marigold-dev/batcher">
          <GithubOutlined style={{ color: '#FFFFFF' }} />
        </a>
      </Space>
    </FooterToolbar>
  );
};

export default Footer;
