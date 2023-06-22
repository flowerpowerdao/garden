import Time "mo:base/Time";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);

  // SYSTEM
  stable var gardenStable : Garden.Stable = null;

  system func preupgrade() {
    gardenStable := garden.toStable();
  };

  system func postupgrade() {
    garden.loadStable(gardenStable);
    gardenStable := null;
  };

  // PUBLIC
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

  public query ({caller}) func me() : async Nat {
    Blob.toArray(Principal.toBlob(caller)).size();
  };
};