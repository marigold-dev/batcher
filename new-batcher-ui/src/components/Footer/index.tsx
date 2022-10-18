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
    <Space>
      <h1 style={{ marginBottom: '0', fontSize: '16px', color: '#FFFFFF' }}>MARIGOLD</h1>
      <Image src={MarigoldLogo}></Image>
    </Space>
  );

  return (
    <FooterToolbar extra={LeftFooter}>
      <Space>
        <TwitterOutlined style={{ color: '#FFFFFF' }} />
        <GithubOutlined style={{ color: '#FFFFFF' }} />
        <LinkedinOutlined style={{ color: '#FFFFFF' }} />
        <GitlabOutlined style={{ color: '#FFFFFF' }} />
      </Space>
    </FooterToolbar>
  );
};

export default Footer;
