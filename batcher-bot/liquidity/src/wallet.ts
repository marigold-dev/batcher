import * as fs from "fs";
import { TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";

export type Wallet = {
  address: string;
  priv_key: string;
};

function validate_wallet(o: any): o is Wallet {
  return "address" in o && "priv_key" in o;
}

export function load(path: string) {
  const content = fs.readFileSync(path, "utf8");
  const parsed = JSON.parse(content);
  if (validate_wallet(parsed)) {
    return parsed;
  } else {
    throw "Incorrect wallet file";
  }
}

export async function loadKey(Tezos: TezosToolkit) {
  const wallet = load("./wallet.json");
  Tezos.setProvider({ signer: await InMemorySigner.fromSecretKey(wallet.priv_key) });

  console.log(await Tezos.signer.publicKeyHash());
  const balance = await Tezos.tz.getBalance('tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb');
  console.log(balance);
}


