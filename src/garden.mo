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

module {

  public class Garden(selfId : Principal) {
    let stakes : Buffer.Buffer<Types.Stake> = Buffer.Buffer<Types.Stake>(0);

    let SECOND = 1_000_000_000;
    let HOUR = SECOND * 60 * 60;

    let SEED_REWARD_PER_HOUR = 1_000_000;
    let MIN_STAKE_PERIOD = HOUR * 24 * 7;

    public func setTimers() {
      ignore Timer.recurringTimer(#seconds(60 * 60), func() : async () {
        ignore tick();
      });
    };

    public func tick() : async () {
      let now = Time.now();

      var i = 0;
      for (stake in stakes.vals()) {
        let stakeEndTime = stake.stakedAt + stake.period;

        // disburse SEED token rewards
        let seedAmount = _getSeedAmountForDuration(Int.min(stakeEndTime, now) - stake.lastDisbursedAt);
        if (seedAmount > 0) {
          let res = await Actors.seed.icrc1_transfer({
            to = stake.account;
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = seedAmount;
          });

          switch (res) {
            case (#Ok(index)) {
              stakes.put(i, {
                stake with
                lastDisbursedAt = now;
              });

              // remove expired stakes
              if (stake.stakedAt + stake.period >= now) {
                ignore stakes.remove(i);

                // transfer NFT back to the owner
                let collectionActor = Actors.getActor(stake.nft.collection);
                await collectionActor.transfer({
                  subaccount = stake.account.subaccount;
                  from = #address(AccountId.fromPrincipal(selfId, stake.account.subaccount)); // todo
                  to = #address(AccountId.fromPrincipal(selfId, stake.account.subaccount)); // todo
                  token = ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(collectionActor), Nat32.fromNat(nft.tokenIndex));
                  amount = 1;
                  notify = false;
                  memo = [];
                });
              };
            };
            case (#Err(err)) {};
          };
        };

        i += 1;
      };
    };

    func _getSeedAmountForDuration(duration : Time.Time) : Nat {
      if (duration <= 0) {
        return 0;
      };
      Int.abs(duration) * SEED_REWARD_PER_HOUR / HOUR;
    };

    public func isStaked(nft : Types.NFT) : Bool {
      for (stake in stakes.vals()) {
        if (stake.nft == nft) {
          return true;
        };
      };
      return false;
    };

    public func stake(account : Types.Account, nft : Types.NFT, period : Time.Time) : async Result.Result<(), Text.Text> {
      if (isStaked(nft)) {
        return #err("Flower already staked");
      };
      if (account.subaccount != null) {
        return #err("Subaccounts are not supported");
      };
      if (period < MIN_STAKE_PERIOD) {
        return #err("Minimum stake period is 7 days");
      };

      // TODO: stakingAccount and userAccount
      let collectionActor = Actors.getActor(nft.collection);
      let ownerArr = Blob.toArray(Principal.toBlob(account.owner));
      let subaccount = Array.tabulate<Nat8>(32, func i = if (i < ownerArr.size()) ownerArr[i] else 0);
      let accountId = AccountId.fromPrincipal(selfId, ?subaccount);

      // check if user sent the NFT to the garden
      let tokens = await collectionActor.tokens(accountId);

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
            account;
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