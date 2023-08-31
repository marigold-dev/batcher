import { liquidity_settings } from "./types";

const path = require("path");
const fs = require("fs-extra");

export const load_settings = (settings_path: string): liquidity_settings => {
  let resolved_path = path.parse(settings_path);
  if (!path.isAbsolute(settings_path)) {
    resolved_path = path.join(path.dirname(__filename), settings_path);
  }
  resolved_path = path.normalize(resolved_path);
  const settings = fs.readJsonSync(resolved_path);

  const tpm = new Map();

  for (let i = 0; i < Object.keys(settings.token_pairs).length; i++) {
    const tp = settings.token_pairs[i];
    const tsett = {
      name: tp.name,
      side: tp.side,
      buy_limit_per_batch: tp.buy_limit_per_batch,
      buy_tolerance: tp.buy_tolerance,
      sell_limit_per_batch: tp.sell_limit_per_batch,
      sell_tolerance: tp.sell_tolerance,
    };
    tpm.set(tp.name, tsett);
  }
  console.info("Liquidity Settings", tpm);

  return {
    batcher_address: settings.batcher_address,
    tezos_node_uri: settings.tezos_node_uri,
    tzkt_uri_api: settings.tzkt_uri_api,
    token_pairs: tpm,
  };
};
