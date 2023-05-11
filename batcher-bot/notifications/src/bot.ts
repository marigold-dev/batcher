import { TezosToolkit } from "@taquito/taquito";
import { Telegraf } from "telegraf";
import { interval } from "rxjs";
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import { format } from "./formatter";
import {
  NotificationsEnabled,
  TelegramMessageContents,
  MessageType,
} from "./types";
import { Option } from "prelude-ts";

const contractAddress = process.env["BATCHER_ADDRESS"];
const channelId = process.env["CHANNEL_ID"];
const tzktUri = process.env["TZKT_URI_API"];

const sendToTelegram = async (bot: Telegraf, message: string, options: any) => {
  console.info("Sending message:", message);
  console.info("With options", options);
  await bot.telegram.sendMessage(channelId, message, options);
};

const init = async (
  bot: Telegraf,
  socketConnection: HubConnection,
  notifications_enabled: NotificationsEnabled
) => {
  await socketConnection.start();

  await socketConnection.invoke("SubscribeToBigMaps", {
    contract: contractAddress,
  });

  await socketConnection.invoke("SubscribeToOperations", {
    address: contractAddress,
    types: "transaction",
  });

  socketConnection.on("bigmaps", (msg: any) => {
    if (!msg.data) return;
    console.info("----->>>>>   Bigmap recevied ", msg.data);
    for (let i = 0; i < Object.keys(msg.data).length; i++) {
      try {
        if (
          msg.data[i].path == "rates_current" ||
          msg.data[i].path == "batch_set.batches"
        ) {
          const formattedMessageOpt = format(
            MessageType.BIGMAP,
            msg.data[i],
            notifications_enabled
          );
          if (formattedMessageOpt.isSome()) {
            const formattedMessage = formattedMessageOpt.get();
            console.info("Bigmap formatted contents", formattedMessage);
            sendToTelegram(
              bot,
              formattedMessage.message,
              formattedMessage.message_options
            );
          }
        }
      } catch (error) {
        console.info("Error parsing bigmap", error.message);
        console.error(error);
      }
    }
  });
  socketConnection.on("operations", (msg: any) => {
    if (!msg.data) return;
    for (let i = 0; i < Object.keys(msg.data).length; i++) {
      try {
        if (msg.data[i].parameter) {
          if (msg.data[i].parameter.entrypoint == "deposit") {
            const formattedMessageOpt = format(
              MessageType.OPERATION,
              msg.data[i],
              notifications_enabled
            );
            if (formattedMessageOpt.isSome()) {
              const formattedMessage = formattedMessageOpt.get();
              console.info("formattedMessage", formattedMessage);
              sendToTelegram(
                bot,
                formattedMessage.message,
                formattedMessage.message_options
              );
            }
          }
        }
      } catch (error) {
        console.info("Error parsing operation", error.message);
        console.error(error);
      }
    }
  });
};

export const start = (
  bot: Telegraf,
  socketConnection: HubConnection,
  notifications_enabled: NotificationsEnabled
) => {
  // Start the web socket
  init(bot, socketConnection, notifications_enabled).then((r) =>
    console.info("started socket")
  );
  socketConnection.onclose(() =>
    init(bot, socketConnection, notifications_enabled)
  );
  // Start the Telegram bot.
  bot.launch();
};
