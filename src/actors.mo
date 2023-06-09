import Types "./types";
import Ext "./interfaces/ext";
import ICRC1 "./interfaces/icrc1";

module {
  public let BTC_FLOWER = actor("pk6rk-6aaaa-aaaae-qaazq-cai") : Ext.Service;
  public let ETH_FLOWER = actor("dhiaa-ryaaa-aaaae-qabva-cai") : Ext.Service;
  public let ICP_FLOWER = actor("4ggk4-mqaaa-aaaae-qad6q-cai") : Ext.Service;
  public let SEED = actor("zzzzp-iiaaa-aaaaf-a5hga-cai") : ICRC1.Service;

  public func getActor(collection : Types.Collection) : Ext.Service {
    switch (collection) {
      case (#BTCFlower) BTC_FLOWER;
      case (#ETHFlower) ETH_FLOWER;
      case (#ICPFlower) ICP_FLOWER;
    };
  };
};