#import "../tokenmanager.mligo" "TokenManager"
let f(_:unit) : TokenManager.TokenManager.storage = {
  valid_tokens = {
    keys  = Set.literal ["tzBTC";"BTCtz";"EURL";"USDT";"USDtz"];   
    values = Big_map.literal [
    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("BTCtz"), {
      token_id = 0n;
      name = "BTCtz";
      address = Some(("KT1ErLEYVsxqHxLgLucXViq5DYrtSyDuSFTe" : address));
      decimals = 8n;
      standard = Some "FA2 token"
    });
    (("EURL"),{
      token_id = 0n;
      name = "EURL";
      address = Some(("KT1RcHjqDWWycYQGrz4KBYoGZSMmMuVpkmuS" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      token_id = 0n;
      name = "USDT";
      address = Some(("KT1WNrZ7pEbpmYBGPib1e7UVCeC6GA6TkJYR" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDtz"),{
      token_id = 0n;
      name = "USDtz";
      address = Some(("KT1B8tP5Q8Cb7HctLfxt4MVk2cWouHFrnbjW" : address));
      decimals = 6n;
      standard = Some "FA1.2 token"
    })
  ];
  };
  valid_swaps  = {
   keys = Set.literal ["tzBTC-USDT";"USDtz-BTCtz";"tzBTC-USDtz";"USDT-BTCtz";"tzBTC-EURL"] ;
   values = Big_map.literal [
    ("tzBTC-USDT", {
        swap = {
            from =  "tzBTC";
            to =  "USDT";
        };
        oracle_address = ("KT1C5Y5dWWEP9Ucxsdmgb3PSPiYQ2Qcgo9xM": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("USDtz-BTCtz", {
        swap = {
            from =  "BTCtz";
            to =  "USDtz";
        };
        oracle_address = ("KT1C5Y5dWWEP9Ucxsdmgb3PSPiYQ2Qcgo9xM": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC-USDtz", {
        swap = {
            from =  "tzBTC";
            to =  "USDtz";
        };
        oracle_address = ("KT1C5Y5dWWEP9Ucxsdmgb3PSPiYQ2Qcgo9xM": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("USDT-BTCtz", {
        swap = {
            from =  "BTCtz";
            to =  "USDT";
        };
        oracle_address = ("KT1C5Y5dWWEP9Ucxsdmgb3PSPiYQ2Qcgo9xM": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC-EURL", {
        swap = {
          from = "tzBTC";
          to = "EURL";
        };
        oracle_address = ("KT1C5Y5dWWEP9Ucxsdmgb3PSPiYQ2Qcgo9xM": address);
        oracle_asset_name = "BTC-EUR";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  };
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  limit_on_tokens_or_pairs = 10n;
}

