const ENV_VARS = [
  'network_target',
  'batcher_uri',
  'batcher_logo_path', // TODO attention
  'tezos_node_uri',
  'tzkt_api_uri', // tODO attention
  'local_storage_key_state',
  'ga_tracking_id',
];

const ghostnet = {
  network_target: 'GHOSTNET',
  batcher_uri: 'https://ghostnet.batcher.marigold.dev',
  batcher_logo_path:
    'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
  tezos_node_uri: 'https://ghostnet.tezos.marigold.dev/',
  tzkt_api_uri: 'https://api.ghostnet.tzkt.io',
  local_storage_key_state: 'batcher-state',
  ga_tracking_id: 'G-2K59PEELC8',
};

const mainnet = {
  network_target: 'MAINNET',
  batcher_uri: 'https://batcher.marigold.dev',
  batcher_logo_path:
    'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
  tezos_node_uri: 'https://mainnet.tezos.marigold.dev/',
  tzkt_api_uri: 'https://api.tzkt.io',
  local_storage_key_state: 'batcher-state',
  ga_tracking_id: 'G-2K59PEELC8',
};

const toEnvVar = vars =>
  Object.entries(vars)
    .map(([k, v]) => [`NEXT_PUBLIC_${k.toUpperCase()}`, v])
    .reduce((acc, current) => ({ ...acc, [current[0]]: current[1] }), {});

const isConfigOK = vars => {
  return ENV_VARS.every(name => Object.keys(vars).includes(name));
};

module.exports = {
  ghostnet,
  mainnet,
  toEnvVar,
  isConfigOK,
};
