import { HubConnection } from "@microsoft/signalr";
import {
  contract_details,
  liquidity_settings,
  batch_provision,
  token_pair,
} from "./types";
import { parse_deposit } from "./utils";
import { submit_deposit, submit_redemption } from "./submitter";
import { can_provision_always_on, can_provision_jit } from "./provision";

const redeem_on_cleared = (msg: any) => {
  for (let i = 0; i < Object.keys(msg.data).length; i++) {
    try {
      const message = msg.data[i];
      if (message.path == "batch_set.batches") {
        const val = message.content.value;
        const batch_number = val.batch_number;
        const status = Object.keys(val.status)[0];
        console.info("Recieved bigmap of status", status);
        if (status == "cleared") {
          console.info(`Batch ${batch_number} was cleared. Redeeming `);
          submit_redemption();
        }
      }
    } catch (error: any) {
      console.info("Error parsing bigmap for redemption", error);
      console.error(error);
    }
  }
};
const getPairName = (fromName: string, toName: string) => {
  if (fromName > toName) {
    return fromName + "/" + toName;
  }

  return toName + "/" + fromName;
};

const always_on_provision = (
  message: any,
  details: contract_details,
  settings: liquidity_settings
) => {
  for (let i = 0; i < Object.keys(message.data).length; i++) {
    try {
      const msg = message.data[i];
      console.info("Always on message", msg);
      if (msg.path == "batch_set.batches") {
        console.info("Is batch change");
        const val = message.content.value;
        const batch_number = val.batch_number;
        const status = Object.keys(val.status)[0];
        const raw_pair = val.pair;
        console.info("pair", val.pair);
        console.info("status", val.status);
        console.info("batch_number", batch_number);
        console.info("Recieved bigmap of status", status);
        if (status == "open") {
          console.info(`Batch ${batch_number} is open. Provisioning liquidity`);
          const pair: string = getPairName(raw_pair.name_0, raw_pair.name_1);
          if (settings.token_pairs.has(pair)) {
            const setting = settings.token_pairs.get(pair);
            if (setting) {
               let buy_token = {
                 token_id: raw_pair.token_id_0,
                 name: raw_pair.name_0,
                 decimals: raw_pair.decimals_0,
                 standard: raw_pair.standard_0,
                 address: raw_pair.address_0,
               };
               let sell_token = {
                 token_id: raw_pair.token_id_1,
                 name: raw_pair.name_1,
                 decimals: raw_pair.decimals_1,
                 standard: raw_pair.standard_1,
                 address: raw_pair.address_1,
               };

              const order_list_opt = can_provision_always_on(
                batch_number,
                setting,
                buy_token,
                sell_token,
                details
              );

              if (order_list_opt.isSome()) {
                const ords = order_list_opt.get();
                for (let j = 0; j < ords.length; j++) {
                  let ord = ords[i];
                  console.info("Provisioning -> ", ord);
                  submit_deposit(ord);
                }
              }
            }
          }
        }
      }
    } catch (error: any) {
      console.error(error);
    }
  }
};

const jit_provision = (
  message: any,
  details: contract_details,
  settings: liquidity_settings
) => {
  for (let i = 0; i < Object.keys(message.data).length; i++) {
    try {
      const msg = message.data[i];
      if (msg.parameter) {
        const entrypoint = msg.parameter.entrypoint;
        if (entrypoint == "deposit") {
          console.info("Deposit message", msg);
          const val = msg.parameter.value;
          const pair: string = getPairName(
            val.swap.from.token.name,
            val.swap.to.name
          );

          const current_batch_indices =
            msg.storage.batch_set.current_batch_indices;
          const batch_number = current_batch_indices[pair];

          if (settings.token_pairs.has(pair)) {
            const jit_setting = settings.token_pairs.get(pair);
            console.info("Deposit value", val);
            if (jit_setting) {
              const order = parse_deposit(val);
              const order_opt = can_provision_jit(
                batch_number,
                jit_setting,
                order
              );
              if (order_opt.isSome()) {
                const ord = order_opt.get();
                console.info("Provisioning -> ", ord);
                submit_deposit(ord);
              }
            }
          }
        }
      }
    } catch (error: any) {
      console.error(error);
    }
  }
};

export const run_jit = async (
  details: contract_details,
  settings: liquidity_settings,
  socket_connection: HubConnection
) => {
  await socket_connection.start();

  await socket_connection.invoke("SubscribeToOperations", {
    address: details.address,
    types: "transaction",
  });

  await socket_connection.invoke("SubscribeToBigMaps", {
    contract: details.address,
  });

  socket_connection.on("operations", (msg: any) => {
    if (!msg.data) return;
    jit_provision(msg, details, settings);
  });

  socket_connection.on("bigmaps", (msg: any) => {
    if (!msg.data) return;
    redeem_on_cleared(msg);
  });
};

export const run_always_on = async (
  details: contract_details,
  settings: liquidity_settings,
  socket_connection: HubConnection
) => {
  await socket_connection.start();

  await socket_connection.invoke("SubscribeToBigMaps", {
    contract: details.address,
  });

  socket_connection.on("bigmaps", (msg: any) => {
    if (!msg.data) return;
    always_on_provision(msg, details, settings);
    redeem_on_cleared(msg);
  });
};
