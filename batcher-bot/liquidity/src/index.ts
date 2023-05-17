#!/usr/bin/env node
import { TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";
import { run_jit, run_always_on } from "./bot";
import { contract_details, liquidity_settings } from "./types";
import { load_settings } from "./settings";
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import { get_contract_detail_from_storage, echo_terminal } from "./utils";
import { Option } from "prelude-ts";
const clear = require("clear");
const { Command } = require("commander");
const cli = new Command();

clear();

echo_terminal("Batcher Bot", Option.none());

const get_connection = (uri: string): HubConnection => {
  return new HubConnectionBuilder().withUrl(uri + "/v1/ws").build();
};
const preload = async (
  tezos: TezosToolkit,
  settings: liquidity_settings
): Promise<contract_details> => {
  const contract_uri: string = `${settings.tzkt_uri_api}/v1/contracts/${settings.batcher_address}/storage`;
  console.info("contract_uri", contract_uri);
  tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(
      process.env["TEZOS_PRIV_KEY"] || "No priv key defined"
    ),
  });

  const user_address = await tezos.signer.publicKeyHash();
  return fetch(contract_uri)
    .then((response) => response.json())
    .then((json) => {
      return get_contract_detail_from_storage(
        user_address,
        settings.batcher_address,
        json
      );
    });
};

cli
  .name("batcher-liquidity-bot")
  .version("0.0.1")
  .description("Batcher Liquidity Bot CLI");

cli
  .command("jit")
  .description("Run Jit liquidity for Batcher")
  .argument("<string>", "Path to settings file")
  .action((p: string) => {
    const sett = load_settings(p);
    const socket_connection = get_connection(sett.tzkt_uri_api);
    const Tezos = new TezosToolkit(sett.tezos_node_uri);
    preload(Tezos, sett).then((contract_config: contract_details) => {
      echo_terminal("Just-In-Time-Liquidity", Option.of("Mnemonic"));
      run_jit(Tezos, contract_config, sett, socket_connection);
    });
  });

cli
  .command("always-on")
  .description("Run always-on liquidity for Batcher")
  .argument("<string>", "Path to settings file")
  .action((p: string) => {
    const sett = load_settings(p);
    const socket_connection = get_connection(sett.tzkt_uri_api);
    const Tezos = new TezosToolkit(sett.tezos_node_uri);
    preload(Tezos, sett).then((contract_config: contract_details) => {
      echo_terminal("Always-On-Liquidity", Option.of("Mnemonic"));
      run_always_on(Tezos, contract_config, sett, socket_connection);
    });
  });

cli.parse(process.argv);

if (!process.argv.slice(2).length) {
  cli.outputHelp();
}
