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

import Types "./types";
import Actors "./actors";
import AccountId "./account-id";
import ExtCore "./toniq-labs/ext/Core";
import Utils "utils";

module {
  public class Garden(selfId : Principal, initArgs : Types.InitArgs) {
    let stakes : Buffer.Buffer<Types.Stake> = Buffer.Buffer<Types.Stake>(0);

    let SECOND = 1_000_000_000;
    let HOUR = SECOND * 60 * 60;

    public func setTimers() {
      ignore Timer.recurringTimer(#nanoseconds(Utils.toNanos(initArgs.disbursementInterval)), func() : async () {
        ignore _tick();
      });
    };

    func _tick() : async () {
      let now = Time.now();

      var i = 0;
      for (stake in stakes.vals()) {
        let stakeEndTime = stake.stakedAt + stake.period;


        let seedAmount = _getSeedAmountForDuration(Int.min(stakeEndTime, now) - stake.lastDisbursedAt);

        var disbursed = seedAmount == 0;

        if (seedAmount > 0) {
          // disburse SEED token rewards
          let res = await Actors.SEED.icrc1_transfer({
            to = {
              owner = stake.principal;
              subaccount = null;
            };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = seedAmount;
          });

          switch (res) {
            case (#Ok(index)) {
              // update last disbursed time
              stakes.put(i, {
                stake with
                lastDisbursedAt = now;
              });

              disbursed := true;
            };
            case (#Err(err)) {};
          };
        };

        if (disbursed and stake.stakedAt + stake.period >= now) {
          // transfer NFT back to the owner
          let collectionActor = Actors.getActor(stake.nft.collection);
          let res = await collectionActor.transfer({
            subaccount = ?getStakingSubaccount(stake.principal); // from subaccount
            from = #address(getStakingAccountId(stake.principal));
            to = #address(AccountId.fromPrincipal(stake.principal, null));
            token = _nftToTokenId(stake.nft);
            amount = 1;
            notify = false;
            memo = [];
          });

          // remove expired stake
          switch (res) {
            case (#ok(_)) {
              ignore stakes.remove(i);
            };
            case (#err(_)) {};
          };
        };

        i += 1;
      };
    };

    func _getSeedAmountForDuration(duration : Time.Time) : Nat {
      if (duration <= 0) {
        return 0;
      };
      Int.abs(duration) * initArgs.seedRewardPerHour / HOUR;
    };

    func _nftToTokenId(nft : Types.NFT) : ExtCore.TokenIdentifier {
      let collectionActor = Actors.getActor(nft.collection);
      ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(collectionActor), Nat32.fromNat(nft.tokenIndex))
    };

    public func isStaked(nft : Types.NFT) : Bool {
      for (stake in stakes.vals()) {
        if (stake.nft == nft) {
          return true;
        };
      };
      return false;
    };

    func getStakingSubaccount(principal : Principal) : [Nat8] {
      let principalArr = Blob.toArray(Principal.toBlob(principal));
      let subaccount = Array.tabulate<Nat8>(32, func i = if (i < principalArr.size()) principalArr[i] else 0);
      subaccount;
    };

    public func getStakingAccountId(principal : Principal) : AccountId.AccountIdentifier {
      let subaccount = getStakingSubaccount(principal);
      AccountId.fromPrincipal(selfId, ?subaccount);
    };

    public func stake(principal : Principal, nft : Types.NFT, period : Time.Time) : async Result.Result<(), Text.Text> {
      if (isStaked(nft)) {
        return #err("Flower already staked");
      };
      if (period < Utils.toNanos(initArgs.minStakePeriod)) {
        return #err("Minimum stake period is " # debug_show(initArgs.minStakePeriod));
      };

      let stakingAccountId = getStakingAccountId(principal);

      // check if user sent the NFT to the garden
      let collectionActor = Actors.getActor(nft.collection);
      let tokens = await collectionActor.tokens(stakingAccountId);

      switch (tokens) {
        case (#ok(tokens)) {
          var hasToken = false;
          for (tokenIndex in tokens.vals()) {
            if (Nat32.toNat(tokenIndex) == nft.tokenIndex) {
              hasToken := true;
            };
          };
          if (not hasToken) {
            return #err("Flower not found in the garden");
          };

          stakes.add({
            principal;
            nft;
            stakedAt = Time.now();
            lastDisbursedAt = Time.now();
            period;
          });

          #ok;
        };
        case (#err(err)) {
          return #err(debug_show(err));
        };
      };
    };
  };
};