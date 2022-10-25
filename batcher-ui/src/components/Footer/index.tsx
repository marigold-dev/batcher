import {
  TwitterOutlined,
  GithubOutlined,
  LinkedinOutlined,
  GitlabOutlined,
} from '@ant-design/icons';
import { FooterToolbar } from '@ant-design/pro-components';
import { Space, Button, Image } from 'antd';
import React from 'react';
import MarigoldLogo from '../../../img/marigold-logo.png';

const Footer: React.FC = () => {
  const LeftFooter = (
        <a href="https://www.marigold.dev/">
        <Space>
        <h1 style={{ marginBottom: '0', fontSize: '16px', color: '#FFFFFF' }}>MARIGOLD</h1>
        <Image preview={false} src={MarigoldLogo} />
        </Space>
        </a>
  );

  return (
    <FooterToolbar extra={LeftFooter}>
      <Space>
       <a href="https://twitter.com/Marigold_Dev"><TwitterOutlined style={{ color: '#FFFFFF' }}/></a>
        <a href="https://github.com/marigold-dev/batcher"><GithubOutlined style={{ color: '#FFFFFF' }} /></a>
      </Space>
    </FooterToolbar>
  );
};

export default Footer;
