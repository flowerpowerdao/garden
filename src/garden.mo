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
import Iter "mo:base/Iter";

import {DAY} "mo:time-consts";

import Types "./types";
import Actors "./actors";
import AccountId "./account-id";
import ExtCore "./toniq-labs/ext/Core";
import Utils "./utils";

module {
  public type Stable = ?{
    #v1: {
      neurons : [(Types.NeuronId, Types.Neuron)];
      neuronsByUser : [(Principal, [Types.NeuronId])];
      curNeuronId : Nat;
      prevRewardTime : Time.Time;
    };
  };

  public class Garden(selfId : Principal, initArgs : Types.InitArgs) {
    var neurons = TrieMap.TrieMap<Types.NeuronId, Types.Neuron>(Nat.equal, func(x) = Text.hash(Nat.toText(x)));
    var neuronsByUser = TrieMap.TrieMap<Principal, Buffer.Buffer<Types.NeuronId>>(Principal.equal, Principal.hash);
    var curNeuronId = 0;
    var prevRewardTime = Time.now();

    // STABLE DATA
    public func toStable() : Stable {
      ? #v1({
        neurons = Iter.toArray(neurons.entries());
        neuronsByUser = Iter.toArray(
          Iter.map<(Principal, Buffer.Buffer<Types.NeuronId>), (Principal, [Types.NeuronId])>(
            neuronsByUser.entries(),
            func((userId, neuronIds)) {
              (userId, Buffer.toArray(neuronIds));
            }
          ));
        curNeuronId;
        prevRewardTime;
      });
    };

    public func loadStable(stab : Stable) {
      switch (stab) {
        case (? #v1(data)) {
          neurons := TrieMap.fromEntries<Types.NeuronId, Types.Neuron>(data.neurons.vals(), Nat.equal, func(x) = Text.hash(Nat.toText(x)));
          neuronsByUser := TrieMap.fromEntries<Principal, Buffer.Buffer<Types.NeuronId>>(
            Iter.map<(Principal, [Types.NeuronId]), (Principal, Buffer.Buffer<Types.NeuronId>)>(
              data.neuronsByUser.vals(),
              func((userId, neuronIds)) {
                (userId, Buffer.fromArray(neuronIds));
              }
            ), Principal.equal, Principal.hash);
          curNeuronId := data.curNeuronId;
          prevRewardTime := data.prevRewardTime;
        };
        case (null) {};
      };
    };

    // PUBLIC
    let YEAR = DAY * 365;
    let BIG_NUMBER = 1_000_000_000_000_000_000_000;

    public func setTimers() {
      ignore Timer.recurringTimer(#nanoseconds(Utils.toNanos(initArgs.rewardInterval)), func() : async () {
        ignore _mintRewards();
      });
    };

    func _mintRewards() : async () {
      let now = Time.now();
      let totalVotingPower = getTotalVotingPower();
      let elapsedTime = Int.abs(now - prevRewardTime);
      let rewardsForElapsedTime = BIG_NUMBER * initArgs.totalRewardsPerYear / YEAR * elapsedTime / BIG_NUMBER;

      for (neuron in neurons.vals()) {
        switch (neuron.dissolveState) {
          // not dissolving
          case (#DissolveDelay(_)) {
            let votingPower = getNeuronVotingPower(neuron.id);
            let rewards = BIG_NUMBER * votingPower / totalVotingPower * rewardsForElapsedTime / BIG_NUMBER;

            // add rewards to neuron
            neurons.put(neuron.id, {
              neuron with
              rewards = neuron.rewards + rewards;
              totalRewards = neuron.totalRewards + rewards;
            });
          };
          // dissolving
          case (#DissolveTimestamp(_)) {};
        };
      };

      prevRewardTime := now;
    };

    public func getUserNeurons(userId : Principal) : [Types.Neuron] {
      let ?neuronIds = neuronsByUser.get(userId) else return [];

      let userNeurons = Buffer.map<Types.NeuronId, Types.Neuron>(neuronIds, func(neuronId) {
        let ?neuron = neurons.get(neuronId) else Debug.trap("neuron not found");
        neuron;
      });

      Buffer.toArray(userNeurons);
    };

    public func isNeuronOwner(userId : Principal, neuronId : Types.NeuronId) : Bool {
      let userNeurons = getUserNeurons(userId);
      for (neuron in userNeurons.vals()) {
        if (neuron.id == neuronId) {
          return true;
        };
      };
      false;
    };

    public func getTotalVotingPower() : Nat {
      var votingPower = 0;
      for (neuronId in neurons.keys()) {
        votingPower += getNeuronVotingPower(neuronId);
      };
      votingPower;
    };

    public func getUserVotingPower(userId : Principal) : Nat {
      let ?neuronIds = neuronsByUser.get(userId) else return 0;
      var votingPower = 0;

      for (neuronId in neuronIds.vals()) {
        votingPower += getNeuronVotingPower(neuronId);
      };

      votingPower;
    };

    public func getNeuronVotingPower(neuronId : Types.NeuronId) : Nat {
      let ?neuron = neurons.get(neuronId) else Debug.trap("neuron not found");
      var votingPower = 0;

      for (flower in neuron.flowers.vals()) {
        votingPower += getFlowerVotingPower(flower);
      };

      votingPower;
    };

    public func getFlowerVotingPower(flower : Types.Flower) : Nat {
      switch (flower.collection) {
        case (#BTCFlower) 2;
        case (#ETHFlower) 1;
        case (#ICPFlower) 1;
      };
    };

    public func getStakingAccount(userId : Principal, nonce : Nat16) : Types.Account {
      {
        owner = selfId;
        subaccount = ?_getStakingSubaccount(userId, nonce);
      }
    };

    public func stake(userId : Principal, nonce : Nat16) : async Result.Result<Types.NeuronId, Text.Text> {
      let stakingAccount = getStakingAccount(userId, nonce);
      let flowers = await _getFlowersOnAccount(stakingAccount);

      curNeuronId += 1;

      neurons.put(curNeuronId, {
        id = curNeuronId;
        userId;
        stakingAccount;
        flowers;
        createdAt = Time.now();
        dissolveState = #DissolveDelay(Utils.toNanos(initArgs.stakePeriod));
        rewards = 0;
        totalRewards = 0;
      });

      let neuronIds = switch (neuronsByUser.get(userId)) {
        case (?neuronIds) {
          neuronIds;
        };
        case (null) {
          let neuronIds = Buffer.Buffer<Types.NeuronId>(0);
          neuronsByUser.put(userId, neuronIds);
          neuronIds;
        };
      };
      neuronIds.add(curNeuronId);

      #ok(curNeuronId);
    };

    public func restake(userId : Principal, neuronId : Types.NeuronId) : async Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      switch (neurons.get(neuronId)) {
        case (?neuron) {
          neurons.put(neuronId, {
            neuron with
            dissolveState = #DissolveDelay(Utils.toNanos(initArgs.stakePeriod));
          });
          #ok;
        };
        case (null) {
          #err("neuron not found");
        };
      };
    };

    public func claimRewards(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      switch (neurons.get(neuronId)) {
        case (?neuron) {
          if (neuron.rewards == 0) {
            return #ok;
          };

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
                lastWithdrwanAt = Time.now();
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

    public func startDissolving(userId : Principal, neuronId : Types.NeuronId) : Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      let ?neuron = neurons.get(neuronId) else Debug.trap("neuron not found");

      switch (neuron.dissolveState) {
        case (#DissolveDelay(dissolveDelay)) {
          neurons.put(neuronId, {
            neuron with
            dissolveState = #DissolveTimestamp(Time.now() + dissolveDelay);
          });
          #ok;
        };
        case (#DissolveTimestamp(_)) {
          #err("neuron is already dissolving");
        };
      };
    };

    // withdraw flowers/rewards then remove neuron
    public func dissolveNeuron(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      switch (neurons.get(neuronId)) {
        case (?neuron) {
          // withdraw remaining SEED rewards
          let res = await claimRewards(userId, neuronId, toAccount);
          if (res != #ok) {
            return res;
          };

          // withdraw all flowers
          for (flower in neuron.flowers.vals()) {
            // transfer flower to user
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
                  flowers = Array.filter<Types.Flower>(neuron.flowers, func(f) = f != flower);
                });
              };
              case (#err(err)) {
                return #err(debug_show(err));
              };
            };
          };

          // delete neuron
          neurons.delete(neuronId);

          // remove neuron from neuronsByUser
          switch (neuronsByUser.get(userId)) {
            case (?neuronIds) {
              neuronIds.filterEntries(func(i, nid) = nid != neuronId);
            };
            case (null) {};
          };

          #ok;
        };
        case (null) {
          #err("neuron not found");
        };
      };
    };

    // TODO: use nonce
    func _getStakingSubaccount(principal : Principal, nonce : Nat16) : [Nat8] {
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