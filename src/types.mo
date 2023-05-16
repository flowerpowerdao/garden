import Time "mo:base/Time";

module {
  public type Account = {
    owner : Principal;
    subaccount : ?[Nat8];
  };

  public type AccountId = Text;
  public type TokenIndex = Nat;

  public type Collection = {
    #BTCFlower;
    #ETHFlower;
    #ICPFlower;
  };

  public type NFT = {
    collection : Collection;
    tokenIndex : TokenIndex;
  };

  public type Stake = {
    nft : NFT;
    principal : Principal;
    stakedAt : Time.Time;
    lastDisbursedAt : Time.Time;
    period : Time.Time;
  };

  public type Duration = {
    #nanoseconds : Nat;
    #seconds : Nat;
    #minutes : Nat;
    #hours : Nat;
    #days : Nat;
  };

  public type InitArgs = {
    seedRewardPerHour : Nat;
    minStakePeriod : Duration;
  };
};