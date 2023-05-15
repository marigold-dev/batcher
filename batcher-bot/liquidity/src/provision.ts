import { batch_provision, order, token_pair } from "./types";
import { Option } from "prelude-ts";

const provision = new Map<number, batch_provision>();

export const can_provision = (token_pair: token_pair): Option<order> => {
  return Option.none();
};
