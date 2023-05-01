import {text} from "stream/consumers";




export enum MessageType {
  BIGMAP = 0,
  OPERATION = 1
}


const formatRatesCurrent = (rateMessage: any) => {

   console.info("Formatting rates_current", rateMessage);
  try{


   const pl = rateMessage.content.value;
    const numerator = pl.rate.p;
    const denominator = pl.rate.q;
    const name = rateMessage.content.key;
    const valid_swaps = rateMessage.storage.valid_swaps;
    const valid_swap = valid_swaps[name];
    const scale = valid_swap.from.decimals - valid_swap.to.decimals;
    const rate = numerator / denominator;
    const scaledRate  = rate * (10 ** scale);

    return "<u>Oracle Update - <i>" + name + "</i></u>  <b>" + scaledRate + "</b>";
  } catch (error) {
   console.info("Error formatting rates", error.message);
   console.error(error);
   return "<b>error</b>" + error.message;

  }
}


const formatBigMap = (message:any) => {
   console.info("Formatting bigmap", message);
   if(message.path == "rates_current"){
     return formatRatesCurrent(message)
   }
return message;
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

const getPairName = (fromName:string, toName:string) => {
  if (fromName > toName){
    return fromName + "/" + toName;
  }

  return toName + "/" + fromName;
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

    return "<b> TRADE ON " + pair  + "  </b>  <i>" + side + " - " + tolerance + " </i>  for " + amount + " " + message.parameter.value.swap.from.token.name;


}


const formatOperation = (message:any) => {
   console.info("Formatting operation", message);
  const entrypoint = message.parameter.entrypoint;
  if(entrypoint == 'deposit'){
   return formatDeposit(message);
  }
   return "<b>" + JSON.stringify(message)  + "</b>";
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
