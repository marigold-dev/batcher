import { token, swap, contract_details, order } from "./types";
import { Option, None } from "prelude-ts";
const chalk = require("chalk");
const figlet = require("figlet");

export const echo_terminal = (msg: string, font: Option<string>) => {
  let font_to_use = "Larry 3D";
  if (font.isSome()) {
    font_to_use = font.get();
  }
  console.log(
    chalk.bold.bgBlack.redBright(
      figlet.textSync(msg, {
        horizontalLayout: "fitted",
        verticalLayout: "fitted",
        font: font_to_use,
      })
    )
  );
};

export const parse_token = (jt: any): token => {
  return {
    token_id: jt.token_id,
    name: jt.name,
    address: jt.address,
    decimals: jt.decimals,
    standard: jt.standard,
  };
};

export const parse_tokens_from_storage = (storage: any): Map<string, token> => {
  const map = new Map();
  if (storage.valid_tokens) {
    let vt = storage.valid_tokens;
    Object.keys(vt).forEach(key => {
      let token = parse_token(vt[key]);
      map.set(key, token);
    });
  }
  return map;
};

export const get_contract_detail_from_storage = (
  user_address: string,
  address: string,
  storage: any
): contract_details => {
  let tokens = parse_tokens_from_storage(storage);
  return {
    user_address: user_address,
    address: address,
    valid_tokens: tokens,
  };
};

export const parse_deposit = (o: any): order => {
  let side = o.side;
  let tol = o.tolerance;
  let to_token = parse_token(o.swap.to);
  let from_token = parse_token(o.swap.from.token);
  let amount = o.swap.from.amount;

  return {
    side: side,
    tolerance: tol,
    swap: {
      to: to_token,
      from: {
        token: from_token,
        amount: amount,
      },
    },
  };
};
