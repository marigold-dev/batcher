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
     // const scaledPow = buyToken.decimals - sellToken.decimals;
    const scaledRate = numerator / denominator;

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


const formatOperation = (message:any) => {
   console.info("Formatting operation", message);
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
