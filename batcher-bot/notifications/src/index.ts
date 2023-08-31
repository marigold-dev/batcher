import { config } from "dotenv";
import { TezosToolkit } from "@taquito/taquito";
import { Telegraf } from "telegraf";
import { interval } from "rxjs";
import { start } from "./bot";
import { HubConnection, HubConnectionBuilder } from "@microsoft/signalr";
import {
  NotificationsEnabled,
  TelegramMessageContents,
  MessageType,
} from "./types";

config();

const botToken = process.env["BOT_TOKEN"];
const tzktUri = process.env["TZKT_URI_API"];
const notifications = process.env["NOTIFICATIONS"];

const bot = new Telegraf(botToken);
const socketConnection = new HubConnectionBuilder()
  .withUrl(tzktUri + "/v1/ws")
  .build();

let notifications_enabled: NotificationsEnabled = {
  deposits: notifications.includes("deposits"),
  rates: notifications.includes("rates"),
  batch_status: notifications.includes("status_updates"),
};

start(bot, socketConnection, notifications_enabled);
