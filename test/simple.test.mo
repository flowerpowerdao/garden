import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

import ICRC1 "mo:icrc1/ICRC1";
import Token "mo:icrc1/ICRC1/Canisters/Token";
import ICRC1Types "mo:icrc1/ICRC1/Types";
import {test} "mo:test/async";

import {initActors} "mo:actors";
import Debug "mo:base/Debug";

test("test", func() : async () {
  let Actors = await initActors();

  let fee = await Actors.SEED.icrc1_fee();
  Debug.print(debug_show(fee));
});