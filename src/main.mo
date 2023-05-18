import Time "mo:base/Time";
import Result "mo:base/Result";

import Garden "./garden";
import Types "./types";
import AccountId "./account-id";

actor class(selfId : Principal, initArgs : Types.InitArgs) {
  let garden = Garden.Garden(selfId, initArgs);

  public func getStakingAccountId(principal : Principal) : async AccountId.AccountIdentifier {
    garden.getStakingAccountId(principal);
  };

  public func stake(principal : Principal, nft : Types.NFT, period : Time.Time) : async Result.Result<(), Text> {
    await garden.stake(principal, nft, period);
  };

  public func isStaked(nft : Types.NFT) : async Bool {
    garden.isStaked(nft);
  };
};