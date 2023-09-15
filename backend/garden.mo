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
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";

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
    };
  };

  public class Garden(selfId : Principal, initArgs : Types.InitArgs) {
    var neurons = TrieMap.TrieMap<Types.NeuronId, Types.Neuron>(Nat.equal, func(x) = Text.hash(Nat.toText(x)));
    var neuronsByUser = TrieMap.TrieMap<Principal, Buffer.Buffer<Types.NeuronId>>(Principal.equal, Principal.hash);
    var curNeuronId = 0;

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
        };
        case (null) {};
      };
    };

    // PUBLIC
    let BIG_NUMBER = 1_000_000_000_000_000_000_000;
    var timerId = 0;

    public func setTimers() {
      Timer.cancelTimer(timerId);
      timerId := Timer.recurringTimer(#nanoseconds(Utils.toNanos(initArgs.rewardInterval)), func() : async () {
        ignore _mintRewards();
      });
    };

    func _mintRewards() : async () {
      let now = Time.now();

      for (neuron in neurons.vals()) {
        switch (neuron.dissolveState) {
          // not dissolving
          case (#DissolveDelay(_)) {
            let elapsedTime = Int.abs(now - neuron.prevRewardTime);
            let dailyRewards = getNeuronDailyRewards(neuron.id);
            let rewards = BIG_NUMBER * dailyRewards * DAY / elapsedTime / BIG_NUMBER;

            // add rewards to neuron
            neurons.put(neuron.id, {
              neuron with
              rewards = neuron.rewards + rewards;
              totalRewards = neuron.totalRewards + rewards;
              prevRewardTime = now;
            });
          };
          // dissolving
          case (#DissolveTimestamp(_)) {};
        };
      };
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

    public func getNeuronDailyRewards(neuronId : Types.NeuronId) : Nat {
      let ?neuron = neurons.get(neuronId) else Debug.trap("neuron not found");
      var dailyRewards = 0;

      for (flower in neuron.flowers.vals()) {
        dailyRewards += getFlowerDailyRewards(flower);
      };

      dailyRewards;
    };

    public func getFlowerDailyRewards(flower : Types.Flower) : Nat {
      switch (flower.collection) {
        case (#BTCFlower) initArgs.dailyRewards.btcFlower;
        case (#ETHFlower) initArgs.dailyRewards.ethFlower;
        case (#ICPFlower) initArgs.dailyRewards.icpFlower;
      };
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

      if (flowers.size() == 0) {
        return #err("no flowers found");
      };

      curNeuronId += 1;

      neurons.put(curNeuronId, {
        id = curNeuronId;
        userId;
        stakingAccount;
        flowers;
        createdAt = Time.now();
        stakedAt = Time.now();
        dissolveState = #DissolveDelay(Utils.toNanos(initArgs.stakePeriod));
        rewards = 0;
        totalRewards = 0;
        prevRewardTime = Time.now();
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

    public func restake(userId : Principal, neuronId : Types.NeuronId) : Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      switch (neurons.get(neuronId)) {
        case (?neuron) {
          neurons.put(neuronId, {
            neuron with
            dissolveState = #DissolveDelay(Utils.toNanos(initArgs.stakePeriod));
            stakedAt = Time.now();
            prevRewardTime = Time.now();
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
            return #err("no rewards to claim");
          };

          let res = await Actors.SEED.icrc1_transfer({
            to = toAccount;
            amount = neuron.rewards;
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
          });

          switch (res) {
            case (#Ok(index)) {
              neurons.put(neuronId, {
                neuron with
                rewards = 0;
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

    public func dissolveNeuron(userId : Principal, neuronId : Types.NeuronId) : Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      let ?neuron = neurons.get(neuronId) else return #err("neuron not found");

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
    public func disburseNeuron(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Text.Text> {
      assert(isNeuronOwner(userId, neuronId));

      switch (neurons.get(neuronId)) {
        case (?neuron) {
          switch (neuron.dissolveState) {
            case (#DissolveTimestamp(dissolveTimestamp)) {
              if (dissolveTimestamp > Time.now()) {
                return #err("neuron is not dissolved yet");
              };
            };
            case (_) {
              return #err("neuron is not dissolved yet");
            };
          };

          // withdraw remaining SEED rewards
          if (neuron.rewards != 0) {
            let res = await claimRewards(userId, neuronId, toAccount);
            if (res != #ok) {
              return res;
            };
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

    func _getStakingSubaccount(principal : Principal, nonce : Nat16) : [Nat8] {
      let principalArr = Blob.toArray(Principal.toBlob(principal));
      let nonceAr : [Nat8] = [
        Nat8.fromNat(Nat16.toNat(nonce / 256)),
        Nat8.fromNat(Nat16.toNat(nonce % 256)),
      ];
      let subaccount = Array.tabulate<Nat8>(32, func(i) {
        if (i < principalArr.size()) {
          principalArr[i];
        } else if (i == 29 or i == 30) {
          // add nonce
          nonceAr[30 - i];
        } else if (i == 31) {
          // store principal size in last byte
          Nat8.fromNat(principalArr.size());
        } else {
          // pad with 0
          0;
        };
      });
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
            // skip "no tokens" error
            // return Debug.trap("Failed to get tokens for collection " # debug_show(collection) # ": " # debug_show(err));
          };
        };
      };

      Buffer.toArray(flowers);
    };
  };
};