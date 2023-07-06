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

  public type DissolveState = {
    #DissolveDelay : Time.Time; // not dissolving
    #DissolveTimestamp : Time.Time; // dissolving, in this timestamp user can dissolve neuron and withdraw flowers
  };

  public type Neuron = {
    id : Nat;
    userId : Principal;
    stakingAccount : Account;
    createdAt : Time.Time;
    dissolveState : DissolveState;
    flowers : [Flower];
    rewards : Nat; // current rewards balance available for withdrawal
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
    totalRewardsPerYear : Nat;
    stakePeriod : Duration;
    rewardInterval : Duration;
  };
};