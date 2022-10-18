import { Space, Button } from 'antd';
import React from 'react';
import { useModel, FormattedMessage } from 'umi';
import styles from './index.less';

export type SiderTheme = 'light' | 'dark';

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
      <Button type="primary" danger>
        <FormattedMessage id="pages.searchTable.batchDeletion" defaultMessage="Connect Wallet" />
      </Button>
    </Space>
  );
};
export default GlobalHeaderRight;
