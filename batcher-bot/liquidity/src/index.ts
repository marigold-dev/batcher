#!/usr/bin/env node
import { config } from "dotenv";
import { run_jit, run_always_on } from "./bot";
import { liquidity_type, contract_details } from "./types";
import { load_settings } from "./settings";
import { ContractsService } from "@dipdup/tzkt-api";
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import { get_contract_detail_from_storage, echo_terminal } from "./utils";
import { Option, None } from "prelude-ts";
const chalk = require("chalk");
const clear = require("clear");
const figlet = require("figlet");
const { Command } = require("commander");
const cli = new Command();

config();
clear();

echo_terminal("Batcher Bot", Option.none());

const contract_address = process.env["BATCHER_ADDRESS"] || "No address defined";
const tzkt_api_uri = process.env["TZKT_URI_API"] || "No api defined";
const socket_connection = new HubConnectionBuilder()
  .withUrl(tzkt_api_uri + "/v1/ws")
  .build();

const preload = async (): Promise<contract_details> => {
  const contract_uri: string = `${tzkt_api_uri}/v1/contracts/${contract_address}/storage`;
  console.info("contract_uri", contract_uri);
  return fetch(contract_uri)
    .then((response) => response.json())
    .then((json) => {
      return get_contract_detail_from_storage(contract_address, json);
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
    preload().then((contract_config: contract_details) => {
      echo_terminal("Just-In-Time-Liquidity", Option.of("Mnemonic"));
      run_jit(contract_config, sett, socket_connection);
    });
  });

cli
  .command("always-on")
  .description("Run always-on liquidity for Batcher")
  .option("-a, --amount <amount>", "trade amount")
  .action((p: string) => {
    const sett = load_settings(p);
    preload().then((contract_config: contract_details) => {
      echo_terminal("Always-On-Liquidity", Option.of("Mnemonic"));
      run_always_on(contract_config, sett, socket_connection);
    });
  });

cli.parse(process.argv);

if (!process.argv.slice(2).length) {
  cli.outputHelp();
}
