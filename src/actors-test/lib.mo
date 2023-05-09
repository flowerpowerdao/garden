import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";

import ICRC1 "mo:icrc1/ICRC1";
import Token "mo:icrc1/ICRC1/Canisters/Token";

import Types "../types";
import Ext "../interfaces/ext";

module {
  type Actors = {
    SEED : ICRC1.FullInterface;
    BTC_FLOWER : Ext.Service;
    ETH_FLOWER : Ext.Service;
    ICP_FLOWER : Ext.Service;
  };

  public func initActors() : async Actors {
    // SEED
    let decimals = 8;

    func addDecimals(n : Nat) : Nat {
      n * 10 ** decimals
    };

    let pre_mint_account = {
      owner = Principal.fromText("aaaaa-aa");
      subaccount = null;
    };

    let SEED = await Token.Token({
      name = "SEED";
      symbol = "SEED";
      decimals = Nat8.fromNat(decimals);
      fee = 1_000_000;
      max_supply = addDecimals(1_000_000);
      initial_balances = [];
      min_burn_amount = addDecimals(10);
      minting_account = ?pre_mint_account; // defaults to the canister id of the caller
      advanced_settings = null;
    });

    return {
      SEED;
      BTC_FLOWER = actor("pk6rk-6aaaa-aaaae-qaazq-cai") : Ext.Service;
      ETH_FLOWER = actor("dhiaa-ryaaa-aaaae-qabva-cai") : Ext.Service;
      ICP_FLOWER = actor("4ggk4-mqaaa-aaaae-qad6q-cai") : Ext.Service;
    };
  };
};