import {text} from "stream/consumers";




export enum MessageType {
  BIGMAP = 0,
  OPERATION = 1
}

const getPairName = (fromName:string, toName:string) => {
  if (fromName > toName){
    return fromName + "/" + toName;
  }

  return toName + "/" + fromName;
};

const getScaledRate= (rate:any, swap:any) => {
  try{

    const numerator = rate.p;
    const denominator = rate.q;
    const scale = swap.from.token.decimals - swap.to.decimals;
    const rate = numerator / denominator;
    return rate * (10 ** scale);
  } catch (error) {
    console.info("Error scaling rate", error.message);
    console.error(error);
    return 0;
  }

}

const formatRatesCurrent = (rateMessage: any) => {

   console.info("Formatting rates_current", rateMessage);
  try{
    const name = rateMessage.content.key;
    const pl = rateMessage.content.value;
    const scaledRate  = getScaledRate(pl.rate, pl.swap);

    return "<u>Oracle Update - <i>" + name + "</i></u>  <b>" + scaledRate + "</b>";
  } catch (error) {
   console.info("Error formatting rates", error.message);
   console.error(error);
   return "<b>error</b>" + error.message;

  }
}

const formatBatchChange = (message:any) => {
  try{
   const val = message.value;
   const batch_number = val.batch_number;
   const buy_decimals = val.pair.decimals_0;
   const sell_decimals = val.pair.decimals_1;
   const buy_name = val.pair.name_0;
   const sell_name = val.pair.name_1;
   const status = Object.keys(val.status)[0];
   const raw_buy_volume = val.volumes.buy_total_volume;
   const raw_sell_volume = val.volumes.sell_total_volume;
   const buy_volume = raw_buy_volume / (10 ** buy_decimals);
   const sell_volume = raw_sell_volume / (10 ** sell_decimals);

   let status_message = status;

   if(status == 'open'){
      status_message = "Open (" + val.status.open + ")";
   }
   if(status == 'closed'){
      status_message = "Closed (" + val.status.open + ")";
   }
   if(status == 'cleared'){
     let rate = getScaledRate(val.status.cleared.rate, val.status.cleared.swap);
     let rate_name = getPairName(val.status.cleared.swap.from.token.name, val.status.cleared.to.token.name);
     status_message = "Cleared (" + val.status.cleared.at + ") @ " + rate_name + " " + rate  ;
   }

    return "<b> BATCH UPDATE " + batch_number  + "  </b>  <i>" + status_message + "</i> - <b> BUY VOLUME " + buy_volume + " " + buy_name + " | SELL VOLUME " + sell_volume + " " + sell_name;


  } catch (error) {
    console.info("Error formatting batch change");
    console.error(error);
    return "<b>" + JSON.stringify(message.content) + "</b>";
  }
}

const formatBigMap = (message:any) => {
   console.info("Formatting bigmap", message);
   if(message.path == "rates_current"){
     return formatRatesCurrent(message)
   }
   if (message.path == 'batch_set.batches') {
     return formatBatchChange(message);
   }
return "<b>" + JSON.stringify(message.content) + "</b>";
}

const getSide =  (side:number) => {
  if(side == 0){
    return "BUY";
  }

  return "SELL";
}

const getTolerance = (side:number, tolerance:number) => {
  if(side == 0 ){
    if(tolerance == 0){
     return "WORST PRICE / BETTER FILL";
    }

    if(tolerance == 1) {
     return "ORACLE";
    }

    return "BETTER PRICE / WORSE FILL";

  }


    if(tolerance == 0){
     return "BETTER PRICE / WORSE FILL";
    }

    if(tolerance == 1) {
     return "ORACLE";
    }

    return "WORSE PRICE / BETTER FILL";


}

const scaleAmount = (amount: number, tokenDecimals: number) => {
    return amount / (10 ** tokenDecimals);
};


const formatDeposit = (message:any) => {
    const val = message.parameter.value
    const storage = message.storage;
    const side = getSide(val.side);
    const tolerance = getTolerance(val.side, val.tolerance);
    const pair =getPairName(message.parameter.value.swap.from.token.name, message.parameter.value.swap.to.name);
    const from = message.parameter.value.swap.from;
    const to = message.parameter.value.swap.to;
    const amount = scaleAmount(from.amount, from.token.decimals);

    return "<b> TRADE ON " + pair  + "  </b>  <i>" + side + " @ " + tolerance + " </i>  for " + amount + " " + message.parameter.value.swap.from.token.name;


}


const formatOperation = (message:any) => {
   console.info("Formatting operation", message);
  const entrypoint = message.parameter.entrypoint;
  if(entrypoint == 'deposit'){
   return formatDeposit(message);
  }
   return "<b> OP:" + JSON.stringify(message.parameter)  + "</b>";

}

export const format = (msgType: MessageType, message:any) => {
  console.info(message);
  try{
  let html = '';
  if(msgType == MessageType.BIGMAP){
    html =  formatBigMap(message);
  }

  if(msgType == MessageType.OPERATION){
    html = formatOperation(message);
  }

   console.info("Formatting html", html);

   let htmlOptions = {
    parse_mode: 'HTML',
    disable_web_page_preview: true,
   };

   return  [html, htmlOptions];
  } catch (error) {
    console.error(error);
    let textOptions = {
    parse_mode: 'TEXT',
   };
    return [message, textOptions];
  }
}
