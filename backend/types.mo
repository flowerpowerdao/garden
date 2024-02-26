import Time "mo:base/Time";
import Map "mo:map/Map";

module {
  public type Account = {
    owner : Principal;
    subaccount : ?[Nat8];
  };

  public type NeuronId = Nat;
  public type AccountId = Text;
  public type TokenIndex = Nat;

  public type Collection = {
    #BTCFlower;
    #ETHFlower;
    #ICPFlower;
    #BTCFlowerGen2;
  };

  public type Flower = {
    collection : Collection;
    tokenIndex : TokenIndex;
  };

  public type DissolveState = {
    #DissolveDelay : Time.Time; // not dissolving
    #DissolveTimestamp : Time.Time; // dissolving, in this timestamp user can disburse neuron and withdraw flowers
  };

  public type UserGeneric = {
    id : Principal;
    createdAt : Time.Time;
    rewards : Nat; // current rewards balance available for withdrawal
    totalRewards : Nat;
  };

  public type User = UserGeneric and {
    neurons : Map.Map<NeuronId, Neuron>;
  };

  public type UserRes = UserGeneric and {
    neurons : [Neuron];
  };

  public type Neuron = {
    id : Nat;
    userId : Principal;
    stakingAccount : Account;
    createdAt : Time.Time;
    stakedAt : Time.Time;
    dissolveState : DissolveState;
    flower : Flower;
    totalRewards : Nat;
    prevRewardTime : Time.Time; // previous reward minting time
  };

  public type Duration = {
    #nanoseconds : Nat;
    #seconds : Nat;
    #minutes : Nat;
    #hours : Nat;
    #days : Nat;
  };

  public type InitArgs = {
    dailyRewards : {
      btcFlower : Nat;
      ethFlower : Nat;
      icpFlower : Nat;
      btcFlowerGen2 : Nat;
    };
    stakePeriod : Duration;
    rewardInterval : Duration;
    trilogyBonus : Nat; // %
  };
};