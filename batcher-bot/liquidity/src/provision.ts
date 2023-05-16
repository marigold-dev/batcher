import {
  batch_provision,
  order,
  token_pair,
  contract_details,
  token,
} from "./types";
import { Option } from "prelude-ts";

const provision = new Map<number, batch_provision>();

const parse_tolerance = (side: number, tol: string): number => {
  if (side == 0) {
    if (tol == "worse") {
      return 0;
    }

    if (tol == "better") {
      return 2;
    }

    return 1;
  } else {
    if (tol == "worse") {
      return 2;
    }

    if (tol == "better") {
      return 0;
    }

    return 1;
  }
};

const provision_sell = (
  batch_number: number,
  token_pair: token_pair,
  order: order
): Option<order> => {
  let existing_buy_provision = 0;
  let existing_sell_provision = 0;

  let existing_provision = provision.get(batch_number);
  try {
    if (existing_provision) {
      existing_buy_provision = existing_provision.buy_side_provision;
      existing_sell_provision = existing_provision.sell_side_provision;
    }
  } catch {}

  if (token_pair.side == "either" && existing_buy_provision > 0) {
    return Option.none();
  }

  let upper_provision_bound = token_pair.sell_limit_per_batch;
  let remaining = upper_provision_bound - existing_sell_provision;

  if (remaining <= 0) {
    return Option.none();
  }

  let sell_decimals = order.swap.to.decimals;
  let scaled_amount = remaining * 10 ** sell_decimals;

  let prov_order: order = {
    swap: {
      from: {
        token: order.swap.to,
        amount: scaled_amount,
      },
      to: order.swap.from.token,
    },
    side: 1,
    tolerance: parse_tolerance(1, token_pair.sell_tolerance),
  };
  let updated_provision: batch_provision = {
    batch_number: batch_number,
    buy_side_provision: existing_buy_provision,
    sell_side_provision: existing_sell_provision + remaining,
  };

  provision.set(batch_number, updated_provision);

  return Option.of(prov_order);
};

const provision_buy = (
  batch_number: number,
  token_pair: token_pair,
  order: order
): Option<order> => {
  let existing_buy_provision = 0;
  let existing_sell_provision = 0;

  let existing_provision = provision.get(batch_number);
  try {
    if (existing_provision) {
      existing_buy_provision = existing_provision.buy_side_provision;
      existing_sell_provision = existing_provision.sell_side_provision;
    }
  } catch {}

  if (token_pair.side == "either" && existing_sell_provision > 0) {
    return Option.none();
  }

  let upper_provision_bound = token_pair.buy_limit_per_batch;
  let remaining = upper_provision_bound - existing_buy_provision;

  if (remaining <= 0) {
    return Option.none();
  }

  let buy_decimals = order.swap.to.decimals;
  let scaled_amount = remaining * 10 ** buy_decimals;

  let prov_order: order = {
    swap: {
      from: {
        token: order.swap.to,
        amount: scaled_amount,
      },
      to: order.swap.from.token,
    },
    side: 0,
    tolerance: parse_tolerance(0, token_pair.sell_tolerance),
  };
  let updated_provision: batch_provision = {
    batch_number: batch_number,
    buy_side_provision: existing_buy_provision + remaining,
    sell_side_provision: existing_sell_provision,
  };

  provision.set(batch_number, updated_provision);

  return Option.of(prov_order);
};

export const can_provision_always_on = (
  batch_number: number,
  token_pair: token_pair,
  buy_token: token,
  sell_token: token,
  details: contract_details
): Option<Array<order>> => {
  let orders = new Array<order>();
  let s = token_pair.side;

  try {
    let buy_decimals = buy_token.decimals;
    let buy_scaled_amount = token_pair.buy_limit_per_batch * 10 ** buy_decimals;

    let buy_order = {
      swap: {
        from: {
          token: buy_token,
          amount: buy_scaled_amount,
        },
        to: sell_token,
      },
      side: 0,
      tolerance: parse_tolerance(0, token_pair.buy_tolerance),
    };

    let sell_decimals = sell_token.decimals;
    let sell_scaled_amount =
      token_pair.sell_limit_per_batch * 10 ** sell_decimals;

    let sell_order = {
      swap: {
        from: {
          token: sell_token,
          amount: sell_scaled_amount,
        },
        to: buy_token,
      },
      side: 1,
      tolerance: parse_tolerance(1, token_pair.buy_tolerance),
    };

    if ((s = "sell")) {
      orders.push(sell_order);
    }
    if ((s = "buy")) {
      orders.push(buy_order);
    }
    if ((s = "both")) {
      orders.push(buy_order);
      orders.push(sell_order);
    }
  } catch (error: any) {
    console.error(error);
  }

  if (orders.length > 0) {
    return Option.of(orders);
  } else {
    return Option.none();
  }
};

export const can_provision_jit = (
  batch_number: number,
  token_pair: token_pair,
  order: order
): Option<order> => {
  let s = token_pair.side;

  if (order.side == 0) {
    if (s == "both" || s == "either" || s == "sell") {
      return provision_sell(batch_number, token_pair, order);
    }
  }

  if (order.side == 1) {
    if (s == "both" || s == "either" || s == "buy") {
      return provision_buy(batch_number, token_pair, order);
    }
  }

  return Option.none();
};
