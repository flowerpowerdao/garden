import Time "mo:base/Time";

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
  };

  public type Flower = {
    collection : Collection;
    tokenIndex : TokenIndex;
  };

  public type Neuron = {
    id : Nat;
    userId : Principal;
    stakingAccount : Account;
    createdAt : Time.Time;
    dissolveDelay : Time.Time;
    dissolving : Bool;
    flowers : [Flower];
    rewards : Nat; // current rewards balance available for disbursal
    totalRewards : Nat;
    lastDisbursedAt : Time.Time;
  };

  public type Duration = {
    #nanoseconds : Nat;
    #seconds : Nat;
    #minutes : Nat;
    #hours : Nat;
    #days : Nat;
  };

  public type InitArgs = {
    totalRewardsPerYear : Nat;
    stakePeriod : Duration;
    rewardInterval : Duration;
  };
};