import { text } from "stream/consumers";
import {
  NotificationsEnabled,
  TelegramMessageContents,
  MessageType,
} from "./types";
import { Option, None } from "prelude-ts";

const tzktUri = process.env["TZKT_URI_API"];

// eslint-disable-next-line @typescript-eslint/no-shadow
const getPairName = (fromName: string, toName: string) => {
  if (fromName > toName) {
    return fromName + "/" + toName;
  }

  return toName + "/" + fromName;
};

const getScaledRate = (rate_obj: any, swap: any) => {
  try {
    const numerator = rate_obj.p;
    const denominator = rate_obj.q;
    const scale = swap.from.token.decimals - swap.to.decimals;
    const rate = numerator / denominator;
    return rate * 10 ** scale;
  } catch (error) {
    console.info("Error scaling rate", error.message);
    console.error(error);
    return 0;
  }
};

const formatRatesCurrent = (rateMessage: any) => {
  try {
    const name = rateMessage.content.key;
    const pl = rateMessage.content.value;
    const scaledRate = getScaledRate(pl.rate, pl.swap);

    return (
      "<u>Oracle Update - <i>" + name + "</i></u>  <b>" + scaledRate + "</b>"
    );
  } catch (error) {
    console.info("Error formatting rates", error.message);
    console.error(error);
    return "<b>error</b>" + error.message;
  }
};

const formatBatchChange = (message: any): Option<string> => {
  try {
    const val = message.content.value;
    const batch_number = val.batch_number;
    const buy_decimals = val.pair.decimals_0;
    const sell_decimals = val.pair.decimals_1;
    const buy_name = val.pair.name_0;
    const sell_name = val.pair.name_1;
    const status = Object.keys(val.status)[0];
    const raw_buy_volume = val.volumes.buy_total_volume;
    const raw_sell_volume = val.volumes.sell_total_volume;
    const buy_volume = raw_buy_volume / 10 ** buy_decimals;
    const sell_volume = raw_sell_volume / 10 ** sell_decimals;

    let rate_name = getPairName(buy_name, sell_name);
    let status_message = status;

    if (status == "open") {
      status_message = "Open (" + val.status.open + ")";
    }
    if (status == "closed") {
      status_message = "Closed (" + val.status.closed.closing_time + ")";
    }
    if (status == "cleared") {
      let rate = getScaledRate(
        val.status.cleared.rate.rate,
        val.status.cleared.rate.swap
      );
      status_message =
        "Cleared (" + val.status.cleared.at + ") @ " + rate_name + " " + rate;
    }

    if (buy_volume == 0 || sell_volume == 0) {
      return Option.none();
    } else {
      return Option.of(
        "<b> BATCH UPDATE " +
          batch_number +
          " " +
          rate_name +
          "</b>  <i>" +
          status_message +
          "</i> - <b> BUY VOLUME " +
          buy_volume +
          " " +
          buy_name +
          " | SELL VOLUME " +
          sell_volume +
          " " +
          sell_name +
          "</b>"
      );
    }
  } catch (error) {
    console.info("Error formatting batch change");
    console.error(error);
    return Option.none();
  }
};

const formatBigMap = (
  message: any,
  notifications_enabled: NotificationsEnabled
): Option<string> => {
  if (message.path == "rates_current" && notifications_enabled.rates) {
    return Option.of(formatRatesCurrent(message));
  }
  if (
    message.path == "batch_set.batches" &&
    notifications_enabled.batch_status
  ) {
    return formatBatchChange(message);
  }

  return Option.none();
};

const getSide = (side: number) => {
  if (side == 0) {
    return "BUY";
  }

  return "SELL";
};

const getTolerance = (side: number, tolerance: number) => {
  if (side == 0) {
    if (tolerance == 0) {
      return "WORST PRICE / BETTER FILL";
    }

    if (tolerance == 1) {
      return "ORACLE";
    }

    return "BETTER PRICE / WORSE FILL";
  }

  if (tolerance == 0) {
    return "BETTER PRICE / WORSE FILL";
  }

  if (tolerance == 1) {
    return "ORACLE";
  }

  return "WORSE PRICE / BETTER FILL";
};

const scaleAmount = (amount: number, tokenDecimals: number) => {
  return amount / 10 ** tokenDecimals;
};

const formatDeposit = (message: any) => {
  console.info("Formatting deposit message", JSON.stringify(message));
  const val = message.parameter.value;
  const side = getSide(val.side);
  const tolerance = getTolerance(val.side, val.tolerance);
  const pair = getPairName(
    message.parameter.value.swap.from.token.name,
    message.parameter.value.swap.to.name
  );
  const from = message.parameter.value.swap.from;
  const to = message.parameter.value.swap.to;
  const amount = scaleAmount(from.amount, from.token.decimals);

  let batch_id = "";
  let volumes = "";
  try {
    console.info("Message storage", message.storage);
    const storage = message.storage;
    const current_batch_ids = storage.batch_set.current_batch_indices;
    console.info("Current batch ids", current_batch_ids);
    const pair_batch_id = current_batch_ids[pair];
    batch_id = `Batch ${pair_batch_id}`;
  } catch (error) {
    console.error(error);
  }

  return `${batch_id} <b> TRADE ON ${pair}</b>  <i> ${side}@${tolerance}</i>  for  <b>${amount} ${message.parameter.value.swap.from.token.name}</b>`;
};

const formatOperation = (
  message: any,
  notifications_enabled: NotificationsEnabled
): Option<string> => {
  const entrypoint = message.parameter.entrypoint;
  if (entrypoint == "deposit" && notifications_enabled.deposits) {
    return Option.of(formatDeposit(message));
  }
  return Option.none();
};

export const format = (
  msgType: MessageType,
  message: any,
  notifications_enabled: NotificationsEnabled
): Option<TelegramMessageContents> => {
  try {
    let htmlOptions: any = {
      parse_mode: "HTML",
      disable_web_page_preview: true,
    };

    if (msgType == MessageType.BIGMAP) {
      const html: Option<string> = formatBigMap(message, notifications_enabled);
      if (html.isSome()) {
        const htmlMessage: string = html.get();
        return Option.of({
          message: htmlMessage,
          message_options: htmlOptions,
        });
      }
    }

    if (msgType == MessageType.OPERATION) {
      const html = formatOperation(message, notifications_enabled);
      if (html.isSome()) {
        const htmlMessage = html.get();
        return Option.of({
          message: htmlMessage,
          message_options: htmlOptions,
        });
      }
    }

    return Option.none();
  } catch (error) {
    console.error(error);
    let textOptions = {
      parse_mode: "TEXT",
    };
    return Option.none();
  }
};
