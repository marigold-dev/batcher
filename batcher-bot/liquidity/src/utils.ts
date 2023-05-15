import { token, swap, contract_details } from "./types";
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
    address: Option.of(jt.address),
    decimals: jt.decimals,
    standard: Option.of(jt.standard),
  };
};

export const parse_tokens_from_storage = (storage: any): Map<string, token> => {
  const map = new Map();
  if (storage.valid_tokens) {
    let vt = storage.valid_tokens;
    for (let i = 0; i < Object.keys(vt).length; i++) {
      const key = Object.keys(vt)[i];
      let token = parse_token(vt[key]);
      map.set(key, token);
    }
  }
  return map;
};

export const get_contract_detail_from_storage = (
  address: string,
  storage: any
): contract_details => {
  let tokens = parse_tokens_from_storage(storage);
  return {
    address: address,
    valid_tokens: tokens,
  };
};
