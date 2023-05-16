import { batch_provision, order, token_pair } from "./types";
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

  console.info("Existing provision", existing_provision);
  console.info("Upper provision bound", upper_provision_bound);
  console.info("Remaining", remaining);

  if (remaining <= 0) {
    return Option.none();
  }

  let sell_decimals = order.swap.to.decimals;
  console.info("Sell decimals", sell_decimals);
  let scaled_amount = remaining * 10 ** sell_decimals;
  console.info("Scaled amount", scaled_amount);

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
  return Option.none();
};

export const can_provision_jit = (
  batch_number: number,
  token_pair: token_pair,
  order: order
): Option<order> => {
  console.info("Provision-order", order);
  console.info("Provision-token-pair", token_pair);
  console.info("Provision-batch_id", batch_number);

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
