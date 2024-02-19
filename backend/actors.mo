import Types "./types";
import Ext "./interfaces/ext";
import ICRC1 "./interfaces/icrc1";

module {
  public let BTC_FLOWER = actor("pk6rk-6aaaa-aaaae-qaazq-cai") : Ext.Service;
  public let ETH_FLOWER = actor("dhiaa-ryaaa-aaaae-qabva-cai") : Ext.Service;
  public let ICP_FLOWER = actor("4ggk4-mqaaa-aaaae-qad6q-cai") : Ext.Service;
  public let BTC_FLOWER_GEN2 = actor("u2kyg-aaaaa-aaaag-qc5ja-cai") : Ext.Service;
  public let SEED = actor("fua74-fyaaa-aaaan-qecrq-cai") : ICRC1.Service;

  public func getActor(collection : Types.Collection) : Ext.Service {
    switch (collection) {
      case (#BTCFlower) BTC_FLOWER;
      case (#ETHFlower) ETH_FLOWER;
      case (#ICPFlower) ICP_FLOWER;
      case (#BTCFlowerGen2) BTC_FLOWER_GEN2;
    };
  };
};