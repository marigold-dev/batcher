import { config } from 'dotenv';
config();

import { TezosToolkit } from '@taquito/taquito';
import { Telegraf } from 'telegraf';
import { interval } from 'rxjs';
import { start } from "./bot"
import { HubConnection, HubConnectionBuilder } from '@microsoft/signalr';

const contractAddress = process.env["BATCHER_ADDRESS"];
const botToken = process.env["BOT_TOKEN"];
const channelId = process.env["CHANNEL_ID"];
const nodeUri = process.env["TEZOS_NODE_URI"];
const tzktUri = process.env["TZKT_URI_API"];

const bot = new Telegraf(botToken);
const socketConnection = new HubConnectionBuilder().withUrl(tzktUri + '/v1/ws').build();

start(bot, socketConnection);
