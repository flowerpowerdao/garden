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
import Option "mo:base/Option";

import Map "mo:map/Map";
import {DAY} "mo:time-consts";
import NatX "mo:xtended-numbers/NatX";

import Types "./types";
import Actors "./actors";
import AccountId "./account-id";
import ExtCore "./toniq-labs/ext/Core";
import Utils "./utils";

module {
  type Err = Text.Text;
  type Users = Map.Map<Principal, Types.User>;

  public type Stable = ?{
    #v2: {
      users : Users;
      curNeuronId : Nat;
    };
  };

  public class Garden(selfId : Principal, initArgs : Types.InitArgs) {
    var users = Map.new<Principal, Types.User>();
    var curNeuronId = 0;

    // STABLE DATA
    public func toStable() : Stable {
      ?#v2({
        users;
        curNeuronId;
      });
    };

    public func loadStable(stab : Stable) {
      switch (stab) {
        case (?#v2(data)) {
          users := data.users;
          curNeuronId := data.curNeuronId;
        };
        case (null) {};
      };
    };

    // PUBLIC

    // REWARDS
    let BIG_NUMBER = 1_000_000_000_000_000_000_000;
    var timerId = 0;

    public func setTimers() {
      Timer.cancelTimer(timerId);
      timerId := Timer.recurringTimer(#nanoseconds(Utils.toNanos(initArgs.rewardInterval)), func() : async () {
        _mintRewards();
      });
    };

    func _mintRewards() {
      let now = Time.now();

      for (user in Map.vals(users)) {
        var userRewards = 0;
        let userFlowersByCollection = Map.new<Nat8, Nat>();

        for (neuron in Map.vals(user.neurons)) {
          switch (neuron.dissolveState) {
            // not dissolving
            case (#DissolveDelay(_)) {
              let elapsedTime = Int.abs(now - neuron.prevRewardTime);
              let dailyRewards = getFlowerDailyRewards(neuron.flower);
              let neuronRewards = BIG_NUMBER * dailyRewards * elapsedTime / DAY / BIG_NUMBER;

              let collectionIndex : Nat8 = _getCollectionIndex(neuron.flower.collection);
              ignore Map.update<Nat8, Nat>(userFlowersByCollection, Map.n8hash, collectionIndex, func(key, oldVal) = ?(Option.get(oldVal, 0) + 1));

              // add rewards to neuron
              Map.set(user.neurons, Map.nhash, neuron.id, {
                neuron with
                totalRewards = neuron.totalRewards + neuronRewards;
                prevRewardTime = now;
              });

              userRewards += neuronRewards;
            };
            // dissolving
            case (#DissolveTimestamp(_)) {};
          };
        };

        // add trilogy bonus
        let btcFlowers = Option.get(Map.get(userFlowersByCollection, Map.n8hash, _getCollectionIndex(#BTCFlower)), 0);
        let ethFlowers = Option.get(Map.get(userFlowersByCollection, Map.n8hash, _getCollectionIndex(#ETHFlower)), 0);
        let icpFlowers = Option.get(Map.get(userFlowersByCollection, Map.n8hash, _getCollectionIndex(#ICPFlower)), 0);
        let trilogies = Nat.min(1, Nat.min(btcFlowers, Nat.min(ethFlowers, icpFlowers)));

        userRewards += userRewards * (trilogies * initArgs.trilogyBonus) / 100;

        // add rewards to user
        Map.set(users, Map.phash, user.id, {
          user with
          rewards = user.rewards + userRewards;
          totalRewards = user.totalRewards + userRewards;
        });
      };
    };

    public func getClaimableSupply() : Nat {
      var supply = 0;
      for (user in Map.vals(users)) {
        supply += user.rewards;
      };
      supply;
    };

    // USERS
    public func getUser(userId : Principal) : Types.User {
      switch (Map.get(users, Map.phash, userId)) {
        case (?user) { user };
        case (null) {
          let user : Types.User = {
            id = userId;
            createdAt = Time.now();
            neurons = Map.new<Types.NeuronId, Types.Neuron>();
            rewards = 0;
            totalRewards = 0;
          };
          Map.set(users, Map.phash, userId, user);
          user;
        };
      };
    };

    public func getUserNeurons(userId : Principal) : [Types.Neuron] {
      let user = getUser(userId);
      Iter.toArray(Map.vals(user.neurons));
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

    public func getFlowerDailyRewards(flower : Types.Flower) : Nat {
      switch (flower.collection) {
        case (#BTCFlower) initArgs.dailyRewards.btcFlower;
        case (#ETHFlower) initArgs.dailyRewards.ethFlower;
        case (#ICPFlower) initArgs.dailyRewards.icpFlower;
        case (#BTCFlowerGen2) initArgs.dailyRewards.btcFlowerGen2;
      };
    };

    public func getTotalVotingPower() : Nat {
      var votingPower = 0;
      for (user in Map.vals(users)) {
        for (neuron in Map.vals(user.neurons)) {
          votingPower += getFlowerVotingPower(neuron.flower);
        };
      };
      votingPower;
    };

    public func getUserVotingPower(userId : Principal) : Nat {
      let user = getUser(userId);
      var votingPower = 0;

      for (neuron in Map.vals(user.neurons)) {
        votingPower += getFlowerVotingPower(neuron.flower);
      };

      votingPower;
    };

    public func getFlowerVotingPower(flower : Types.Flower) : Nat {
      switch (flower.collection) {
        case (#BTCFlower) 2;
        case (#ETHFlower) 1;
        case (#ICPFlower) 1;
        case (#BTCFlowerGen2) 0;
      };
    };

    // STAKING ACCOUNT
    func _getCollectionIndex(collection : Types.Collection) : Nat8 {
      switch (collection) {
        case (#BTCFlower) 0;
        case (#ETHFlower) 1;
        case (#ICPFlower) 2;
        case (#BTCFlowerGen2) 3;
      };
    };

    func _getStakingSubaccount(principal : Principal, flower : Types.Flower) : [Nat8] {
      let collectionIndex : Nat8 = _getCollectionIndex(flower.collection);

      // 0-29 principal
      let buf = Buffer.fromIter<Nat8>(Principal.toBlob(principal).vals());
      // 30 collection index
      buf.add(collectionIndex);
      // 31-32 token index
      NatX.encodeNat16(buf, Nat16.fromNat(flower.tokenIndex), #msb);

      assert(buf.size() == 32);

      Buffer.toArray(buf);
    };

    public func getStakingAccount(userId : Principal, flower : Types.Flower) : Types.Account {
      if (Principal.isAnonymous(userId) or Principal.toBlob(userId).size() > 29) {
        Debug.trap("invalid userId: " # Principal.toText(userId));
      };

      {
        owner = selfId;
        subaccount = ?_getStakingSubaccount(userId, flower);
      }
    };

    // NEURONS
    public func stake(userId : Principal, flower : Types.Flower) : async Result.Result<Types.NeuronId, Err> {
      let stakingAccount = getStakingAccount(userId, flower);
      let flowerRes = await _checkFlowerOnAccount(flower, stakingAccount);

      switch (flowerRes) {
        case (#err(err)) {
          return #err(err);
        };
        case (#ok) {};
      };

      curNeuronId += 1;

      let user = getUser(userId);

      Map.set(user.neurons, Map.nhash, curNeuronId, {
        id = curNeuronId;
        userId;
        stakingAccount;
        flower;
        createdAt = Time.now();
        stakedAt = Time.now();
        dissolveState = #DissolveDelay(Utils.toNanos(initArgs.stakePeriod));
        rewards = 0;
        totalRewards = 0;
        prevRewardTime = Time.now();
      });

      #ok(curNeuronId);
    };

    public func restake(userId : Principal, neuronId : Types.NeuronId) : Result.Result<(), Err> {
      assert(isNeuronOwner(userId, neuronId));

      let user = getUser(userId);

      switch (Map.get(user.neurons, Map.nhash, neuronId)) {
        case (?neuron) {
          Map.set(user.neurons, Map.nhash, neuronId, {
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

    public func dissolveNeuron(userId : Principal, neuronId : Types.NeuronId) : Result.Result<(), Err> {
      assert(isNeuronOwner(userId, neuronId));

      let user = getUser(userId);
      let ?neuron = Map.get(user.neurons, Map.nhash, neuronId) else return #err("neuron not found");

      switch (neuron.dissolveState) {
        case (#DissolveDelay(dissolveDelay)) {
          Map.set(user.neurons, Map.nhash, neuronId, {
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

    // withdraw flower then remove neuron
    public func disburseNeuron(userId : Principal, neuronId : Types.NeuronId, toAccount : Types.Account) : async Result.Result<(), Err> {
      assert(isNeuronOwner(userId, neuronId));

      let user = getUser(userId);
      let ?neuron = Map.get(user.neurons, Map.nhash, neuronId) else return #err("neuron not found");

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

      // withdraw flower
      let collectionActor = Actors.getActor(neuron.flower.collection);
      let res = await collectionActor.transfer({
        subaccount = neuron.stakingAccount.subaccount; // from subaccount
        from = #address(_accountToAccountId(neuron.stakingAccount));
        to = #address(_accountToAccountId(toAccount));
        token = _nftToTokenId(neuron.flower);
        amount = 1;
        notify = false;
        memo = [];
      });
      switch (res) {
        case (#ok(_)) {};
        case (#err(err)) {
          return #err(debug_show(err));
        };
      };

      // delete neuron
      Map.delete(user.neurons, Map.nhash, neuronId);

      #ok;
    };

    // withdraw SEED tokens
    public func claimRewards(userId : Principal, toAccount : Types.Account) : async Result.Result<(), Err> {
      let user = getUser(userId);

      if (user.rewards == 0) {
        return #err("no rewards to claim");
      };

      let res = await Actors.SEED.icrc1_transfer({
        to = toAccount;
        amount = user.rewards;
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
      });

      switch (res) {
        case (#Ok(_index)) {
          Map.set(users, Map.phash, userId, {
            user with
            rewards = 0;
          });
          #ok;
        };
        case (#Err(err)) {
          #err(debug_show(err));
        };
      };
    };

    func _accountToAccountId(account : Types.Account) : AccountId.AccountIdentifier {
      AccountId.fromPrincipal(account.owner, account.subaccount);
    };

    func _nftToTokenId(nft : Types.Flower) : ExtCore.TokenIdentifier {
      let collectionActor = Actors.getActor(nft.collection);
      ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(collectionActor), Nat32.fromNat(nft.tokenIndex))
    };

    func _checkFlowerOnAccount(flower : Types.Flower, account : Types.Account) : async Result.Result<(), Err> {
      let accountId = AccountId.fromPrincipal(account.owner, account.subaccount);
      let collectionActor = Actors.getActor(flower.collection);
      let tokens = await collectionActor.tokens(accountId);

      switch (tokens) {
        case (#ok(tokens)) {
          for (tokenIndex in tokens.vals()) {
            if (Nat32.toNat(tokenIndex) == flower.tokenIndex) {
              return #ok;
            }
          };
        };
        case (#err(err)) {
          // skip "no tokens" error
          // return Debug.trap("Failed to get tokens for collection " # debug_show(collection) # ": " # debug_show(err));
        };
      };

      return #err("no flowers found on staking account");
    };
  };
};