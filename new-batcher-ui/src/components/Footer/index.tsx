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
      <h1 style={{ marginBottom: '0', fontSize: '16px' }}>MARIGOLD</h1>
      <Image src={MarigoldLogo}></Image>
    </Space>
  );

  return (
    <FooterToolbar extra={LeftFooter}>
      <Space>
        <TwitterOutlined />
        <GithubOutlined />
        <LinkedinOutlined />
        <GitlabOutlined />
      </Space>
    </FooterToolbar>
  );
};

export default Footer;
