import Time "mo:base/Time";
import Result "mo:base/Result";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);

  public shared ({caller}) func getStakingAccount(nonce : Nat32) : async Types.Account {
    garden.getStakingAccount(caller, nonce);
  };

  public shared ({caller}) func stake(nonce : Nat32) : async Result.Result<Types.NeuronId, Text> {
    await garden.stake(caller, nonce);
  };
};