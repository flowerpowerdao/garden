import Time "mo:base/Time";
import Result "mo:base/Result";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);

  public query ({caller}) func getStakingAccount(nonce : Nat16) : async Types.Account {
    garden.getStakingAccount(caller, nonce);
  };

  public shared ({caller}) func stake(nonce : Nat16) : async Result.Result<Types.NeuronId, Text> {
    await garden.stake(caller, nonce);
  };

  public query ({caller}) func getUserNeurons() : async [Types.Neuron] {
    garden.getUserNeurons(caller);
  };

  public query ({caller}) func startDissolving(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.startDissolving(caller, neuronId);
  };
};