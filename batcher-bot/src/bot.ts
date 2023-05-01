
import { TezosToolkit } from '@taquito/taquito';
import { Telegraf } from 'telegraf';
import { interval } from 'rxjs';
import { HubConnection, HubConnectionBuilder } from '@microsoft/signalr';
import { MessageType, format } from './formatter'
const contractAddress = process.env["BATCHER_ADDRESS"];
const botToken = process.env["BOT_TOKEN"];
const channelId = process.env["CHANNEL_ID"];
const nodeUri = process.env["TEZOS_NODE_URI"];
const tzktUri = process.env["TZKT_URI_API"];



const sendToTelegram = async (bot:Telegraf,  message:string, options: any) => {
    await bot.telegram.sendMessage(channelId, message, options);
};

const init = async (bot:Telegraf, socketConnection:HubConnection) => {
  await socketConnection.start();

  await socketConnection.invoke('SubscribeToBigMaps', {
    contract: contractAddress,
  });

  await socketConnection.invoke('SubscribeToOperations', {
    address: contractAddress,
    types: 'transaction',
  });

   socketConnection.on('bigmaps', (msg: any) => {
      if (!msg.data) return;
        const formattedMessage = format(MessageType.BIGMAP, msg.data[0]);
        console.info("formattedMessage", formattedMessage);
        sendToTelegram(bot, formattedMessage[0], formattedMessage[1]);
    });
    socketConnection.on('operations', (msg: any) => {
      if (!msg.data) return;
      if (msg.data[0].parameter.endpoint == tick) return;
        const formattedMessage = format(MessageType.OPERATION, msg.data[0]);
        console.info("formattedMessage", formattedMessage);
        sendToTelegram(bot, formattedMessage[0], formattedMessage[1]);
    });

};

 export const start = (bot:Telegraf, socketConnection: HubConnection) => {
   // Start the web socket
   init(bot, socketConnection).then(r => console.info("started socket"))
   socketConnection.onclose(() => init(bot,socketConnection));
// Start the Telegram bot.
   bot.launch();
};
