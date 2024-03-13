import Time "mo:base/Time";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

import Map "mo:map/Map";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class Main(selfId : Principal, initArgs : Types.InitArgs) {
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
  public query func getClaimableSupply() : async Nat {
    garden.getClaimableSupply();
  };

  public query ({caller}) func getStakingAccount(flower : Types.Flower) : async Types.Account {
    garden.getStakingAccount(caller, flower);
  };

  public shared ({caller}) func stake(flower : Types.Flower) : async Result.Result<Types.NeuronId, Text> {
    await* garden.stake(caller, flower);
  };

  public shared ({caller}) func restake(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.restake(caller, neuronId);
  };

  public query ({caller}) func getCallerUser() : async Types.UserRes {
    let user = garden.getUser(caller);
    {
      user with
      neurons = Iter.toArray(Map.vals(user.neurons));
    };
  };

  public shared ({caller}) func dissolveNeuron(neuronId : Types.NeuronId) : async Result.Result<(), Text> {
    garden.dissolveNeuron(caller, neuronId);
  };

  public shared ({caller}) func claimRewards(toAccount : Types.Account) : async Result.Result<(), Text> {
    await* garden.claimRewards(caller, toAccount);
  };

  public shared ({caller}) func disburseNeuron(neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text> {
    await* garden.disburseNeuron(caller, neuronId, toAccount);
  };

  public shared ({caller}) func withdrawStuckFlower(flower : Types.Flower) : async Result.Result<(), Text> {
    await* garden.withdrawStuckFlower(caller, flower);
  };

  // for fpdao app
  public query ({caller}) func getUserNeurons(userId : Principal) : async [Types.Neuron] {
    assert(caller == Principal.fromText("fqfmg-4iaaa-aaaae-qabaa-cai"));
    garden.getUserNeurons(userId);
  };

  public query ({caller}) func getUserVotingPower(userId : Principal) : async Nat {
    assert(caller == Principal.fromText("fqfmg-4iaaa-aaaae-qabaa-cai"));
    garden.getUserVotingPower(userId);
  };
};