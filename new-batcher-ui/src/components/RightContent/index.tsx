import { Space, Button, Menu, Dropdown, Typography } from 'antd';
import React from 'react';
import { useModel, FormattedMessage } from 'umi';
import styles from './index.less';
import { MenuOutlined } from '@ant-design/icons';

export type SiderTheme = 'light' | 'dark';

const menu = (
  <Menu
    items={[
      {
        key: '1',
        label: <Typography>Connect Wallet</Typography>,
      },
      {
        key: '2',
        label: <Typography>Order books</Typography>,
      },
      {
        key: '3',
        label: <Typography>Redeem holdings</Typography>,
      },
    ]}
  />
);

const GlobalHeaderRight: React.FC = () => {
  const { initialState } = useModel('@@initialState');

  if (!initialState || !initialState.settings) {
    return null;
  }

  const { navTheme, layout } = initialState.settings;
  let className = styles.right;

  if ((navTheme === 'dark' && layout === 'top') || layout === 'mix') {
    className = `${styles.right}  ${styles.dark}`;
  }
  return (
    <Space className={className}>
      <Button className="batcher-connect-wallet" type="primary" danger>
        <FormattedMessage id="pages.searchTable.batchDeletion" defaultMessage="Connect Wallet" />
      </Button>
      <Dropdown overlay={menu} placement="bottomLeft">
        <MenuOutlined className="batcher-menu" />
      </Dropdown>
    </Space>
  );
};
export default GlobalHeaderRight;
