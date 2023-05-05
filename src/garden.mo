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

import Types "./types";
import Actors "./actors";
import AccountId "./account-id";
import Timer "mo:base/Timer";
import Int "mo:base/Int";

module {

  public class Garden(selfId : Principal) {
    let stakes : Buffer.Buffer<Types.Stake> = Buffer.Buffer<Types.Stake>(0);

    let SECOND = 1_000_000_000;
    let HOUR = SECOND * 60 * 60;
    let SEED_PER_HOUR = 1_000_000;

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

        // disburse seed tokens
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

              // remove stakes that have expired
              if (stake.stakedAt + stake.period >= now) {
                ignore stakes.remove(i);
                // TODO: transfer NFT back to owner
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
      Int.abs(duration) * SEED_PER_HOUR / HOUR;
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
        return #err("Token already staked");
      };
      if (account.subaccount != null) {
        return #err("Subaccounts not supported");
      };
      if (period < HOUR * 24 * 7) {
        return #err("Minimum stake period is 7 days");
      };

      let collectionActor = Actors.getActor(nft.collection);
      let ownerArr = Blob.toArray(Principal.toBlob(account.owner));
      let selfSubaccount = Array.tabulate<Nat8>(32, func i = if (i < ownerArr.size()) ownerArr[i] else 0);
      let accountId = AccountId.fromPrincipal(selfId, ?selfSubaccount);

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