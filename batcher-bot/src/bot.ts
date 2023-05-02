
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
      for (let i = 0; i < Object.keys(msg.data).length; i++) {
        console.info("++++ BIGMAPS +++", msg.data[i]);
        try{
      if (msg.data[i].path == 'rates_current') {
        const formattedMessage = format(MessageType.BIGMAP, msg.data[i]);
        console.info("formattedMessage", formattedMessage);
        sendToTelegram(bot, formattedMessage[0], formattedMessage[1]);
      }} catch (error) {
        console.info("Error parsing bigmap", error.message);
        console.error(error);
      }
      }
    });
    socketConnection.on('operations', (msg: any) => {
      if (!msg.data) return;
        console.info("++++ OPERATIONS (RECEIVED) +++", msg.data);
    for (let i = 0; i < Object.keys(msg.data).length; i++) {
      try{
        console.info("++++ OPERATIONS +++", msg.data[i].parameter);
      if (msg.data[i].parameter) {
      if (msg.data[i].parameter.entrypoint == 'deposit') {
        const formattedMessage = format(MessageType.OPERATION, msg.data[i]);
        console.info("formattedMessage", formattedMessage);
        sendToTelegram(bot, formattedMessage[0], formattedMessage[1]);
      }
      }
      } catch (error) {
        console.info("Error parsing operation", error.message);
        console.error(error);
      }
    }
    });

};

 export const start = (bot:Telegraf, socketConnection: HubConnection) => {
   // Start the web socket
   init(bot, socketConnection).then(r => console.info("started socket"))
   socketConnection.onclose(() => init(bot,socketConnection));
// Start the Telegram bot.
   bot.launch();
};
