module.exports = {
  ghostnet: {
    REACT_APP_NETWORK_TARGET: 'GHOSTNET',
    REACT_APP_BATCHER_URI: 'https://ghostnet.batcher.marigold.dev',
    REACT_APP_PATH_TO_BATCHER_LOGO:
      'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
    REACT_APP_TEZOS_NODE_URI: 'https://ghostnet.tezos.marigold.dev/',
    REACT_APP_TZKT_URI_API: 'https://api.ghostnet.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1VsdkeG3PZZ5yraiBJTdKWhT9C8nNiLGu1',
    REACT_APP_LOCAL_STORAGE_KEY_STATE: 'batcher-state',
  },
  mainnet: {
    REACT_APP_NETWORK_TARGET: 'MAINNET',
    REACT_APP_BATCHER_URI: 'https://batcher.marigold.dev',
    REACT_APP_PATH_TO_BATCHER_LOGO:
      'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
    REACT_APP_TEZOS_NODE_URI: 'https://mainnet.tezos.marigold.dev/',
    REACT_APP_TZKT_URI_API: 'https://api.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1CoTu4CXcWoVk69Ukbgwx2iDK7ZA4FMSpJ',
    REACT_APP_LOCAL_STORAGE_KEY_STATE: 'batcher-state',
  },
};
