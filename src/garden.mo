import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat32 "mo:base/Nat32";
import Timer "mo:base/Timer";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

import Types "./types";
import Actors "./actors";
import AccountId "./account-id";
import ExtCore "./toniq-labs/ext/Core";
import Utils "./utils";

module {
  public class Garden(selfId : Principal, initArgs : Types.InitArgs) {
    let neurons = TrieMap.TrieMap<Types.NeuronId, Types.Neuron>(Nat.equal, Nat.hash);
    var curNeuronId = 0;

    let SECOND = 1_000_000_000;
    let HOUR = SECOND * 60 * 60;

    public func setTimers() {
      ignore Timer.recurringTimer(#nanoseconds(Utils.toNanos(initArgs.rewardInterval)), func() : async () {
        ignore _tick();
      });
    };

    func _tick() : async () {
      let now = Time.now();

      for (stake in neurons.vals()) {
        let stakeEndTime = stake.stakedAt + stake.period;

        let seedAmount = _getSeedAmountForDuration(Int.min(stakeEndTime, now) - stake.lastDisbursedAt);
      };
    };

    func _getSeedAmountForDuration(duration : Time.Time) : Nat {
      if (duration <= 0) {
        return 0;
      };
      Int.abs(duration) * initArgs.seedRewardPerHour / HOUR;
    };

    public func isStaked(nft : Types.Flower) : Bool {
      for (stake in neurons.vals()) {
        if (stake.nft == nft) {
          return true;
        };
      };
      return false;
    };

    public func getStakingAccountId(userId : Principal) : AccountId.AccountIdentifier {
      let subaccount = _getStakingSubaccount(userId, 0);
      AccountId.fromPrincipal(selfId, ?subaccount);
    };

    //////////////////////////////////////////
    //////////////////////////////////////////
    //////////////////////////////////////////

    public func getStakingAccount(userId : Principal, nonce : Nat32) : Types.Account {
      {
        owner = selfId;
        subaccount = ?_getStakingSubaccount(userId, nonce);
      }
    };

    public func stake(userId : Principal, nonce : Nat32) : async Result.Result<Types.NeuronId, Text.Text> {
      let stakingAccount = getStakingAccount(userId, nonce);
      let flowers = await _getFlowersOnAccount(stakingAccount);

      curNeuronId += 1;

      neurons.put(curNeuronId, {
        id = curNeuronId;
        userId;
        stakingAccount;
        flowers;
        createdAt = Time.now();
        lastDisbursedAt = Time.now();
        dissolveDelay = Utils.toNanos(initArgs.stakePeriod);
        dissolving = false;
        rewards = 0;
        totalRewards = 0;
      });

      #ok(curNeuronId);
    };

    public func claimRewards(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text.Text> {
      switch (neurons.get(neuronId)) {
        case (?neuron) {
          let res = await Actors.SEED.icrc1_transfer({
            to = toAccount;
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = neuron.rewards;
          });

          switch (res) {
            case (#Ok(index)) {
              neurons.put(neuronId, {
                neuron with
                amount = 0;
                lastDisbursedAt = Time.now();
              });
              #ok;
            };
            case (#Err(err)) {
              #err(debug_show(err));
            };
          };
        };
        case (null) {
          #err("neuron not found");
        };
      };
    };

    // withdraw flowers and remove neuron
    public func dissolveNeuron(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text.Text> {
      switch (neurons.get(neuronId)) {
        case (?neuron) {
          for (flower in neuron.flowers.vals()) {
            let collectionActor = Actors.getActor(flower.collection);
            let res = await collectionActor.transfer({
              subaccount = neuron.stakingAccount.subaccount; // from subaccount
              from = #address(_accountToAccountId(neuron.stakingAccount));
              to = #address(_accountToAccountId(toAccount));
              token = _nftToTokenId(flower);
              amount = 1;
              notify = false;
              memo = [];
            });

            switch (res) {
              case (#ok(_)) {
                // remove flower from neuron
                neurons.put(neuronId, {
                  neuron with
                  amount = 0;
                  lastDisbursedAt = Time.now();
                });
              };
              case (#err(err)) {
                return #err(debug_show(err));
              };
            };
          };

          #ok;
        };
        case (null) {
          #err("neuron not found");
        };
      };
    };

    // TODO: use nonce
    func _getStakingSubaccount(principal : Principal, nonce : Nat32) : [Nat8] {
      let principalArr = Blob.toArray(Principal.toBlob(principal));
      let subaccount = Array.tabulate<Nat8>(32, func i = if (i < principalArr.size()) principalArr[i] else 0);
      subaccount;
    };

    func _accountToAccountId(account : Types.Account) : AccountId.AccountIdentifier {
      AccountId.fromPrincipal(account.owner, account.subaccount);
    };

    func _nftToTokenId(nft : Types.Flower) : ExtCore.TokenIdentifier {
      let collectionActor = Actors.getActor(nft.collection);
      ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(collectionActor), Nat32.fromNat(nft.tokenIndex))
    };

    func _getFlowersOnAccount(account : Types.Account) : async [Types.Flower] {
      let accountId = AccountId.fromPrincipal(account.owner, account.subaccount);
      let collections = [#BTCFlower, #ETHFlower, #ICPFlower];
      let flowers = Buffer.Buffer<Types.Flower>(0);

      for (collection in collections.vals()) {
        let collectionActor = Actors.getActor(collection);
        let tokens = await collectionActor.tokens(accountId);

        switch (tokens) {
          case (#ok(tokens)) {
            for (tokenIndex in tokens.vals()) {
              flowers.add({
                collection;
                tokenIndex = Nat32.toNat(tokenIndex);
              });
            };
          };
          case (#err(err)) {
            return Debug.trap("Failed to get tokens for collection " # debug_show(collection) # ": " # debug_show(err));
          };
        };
      };

      Buffer.toArray(flowers);
    };
  };
};