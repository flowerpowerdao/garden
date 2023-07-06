import Time "mo:base/Time";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);
  garden.setTimers();

  // SYSTEM
  stable var gardenStable : Garden.Stable = null;

  system func preupgrade() {
    gardenStable := garden.toStable();
  };

  system func postupgrade() {
    garden.loadStable(gardenStable);
    gardenStable := null;
    garden.setTimers();
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

  public query ({caller}) func dissolveNeuron(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.dissolveNeuron(caller, neuronId);
  };

  public shared ({caller}) func disburseNeuron(neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text> {
    await garden.disburseNeuron(caller, neuronId, toAccount);
  };

  public query ({caller}) func me() : async Nat {
    Blob.toArray(Principal.toBlob(caller)).size();
  };
};