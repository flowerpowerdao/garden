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

  public shared ({caller}) func restake(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.restake(caller, neuronId);
  };

  public query ({caller}) func getCallerNeurons() : async [Types.Neuron] {
    garden.getUserNeurons(caller);
  };

  public query func getUserNeurons(userId : Principal) : async [Types.Neuron] {
    garden.getUserNeurons(userId);
  };

  public query func getUserVotingPower(userId : Principal) : async Nat {
    garden.getUserVotingPower(userId);
  };

  public shared ({caller}) func dissolveNeuron(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.dissolveNeuron(caller, neuronId);
  };

  public shared ({caller}) func claimRewards(neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text> {
    await garden.claimRewards(caller, neuronId, toAccount);
  };

  public shared ({caller}) func disburseNeuron(neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text> {
    await garden.disburseNeuron(caller, neuronId, toAccount);
  };
};