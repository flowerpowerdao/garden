import { FakeUser } from './utils/fake-user';
import canisterIds from '../.dfx/local/canister_ids.json';

import { idlFactory as idlFactoryMain } from '../declarations/main/index.js';
import { _SERVICE as _SERVICE_MAIN } from '../declarations/main/main.did';

import { idlFactory as idlFactoryExt } from '../declarations/ext/index.js';
import { _SERVICE as _SERVICE_EXT } from '../declarations/ext/ext.did';

import { idlFactory as idlFactorySeed } from '../declarations/icrc1/index.js';
import { _SERVICE as _SERVICE_SEED } from '../declarations/icrc1/icrc1.did';
import { tokenIdentifier } from './utils';


export class User extends FakeUser {
  mainActor = this.createActor<_SERVICE_MAIN>(idlFactoryMain, canisterIds.main.local);
  seedActor = this.createActor<_SERVICE_SEED>(idlFactorySeed, canisterIds.seed.local);
  btcFlowerActor = this.createActor<_SERVICE_EXT>(idlFactoryExt, canisterIds.btcflower.local);
  ethFlowerActor = this.createActor<_SERVICE_EXT>(idlFactoryExt, canisterIds.ethflower.local);
  icpFlowerActor = this.createActor<_SERVICE_EXT>(idlFactoryExt, canisterIds.icpflower.local);
  btcFlowerGen2Actor = this.createActor<_SERVICE_EXT>(idlFactoryExt, canisterIds.btcflower_gen2.local);

  async mintFlower(actor: _SERVICE_EXT, canisterId: string, to: string = this.accountId) {
    let minter = new User('minter');
    let tokens = await actor.tokens(minter.accountId);

    if (tokens['err'] || tokens['ok'].length == 0) {
      throw new Error('Minter has no tokens');
    }

    await actor.transfer({
      amount: 1n,
      from: { address: minter.accountId },
      to: { address: to },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterId, tokens['ok'][0]),
    });
  }

  async mintBTCFlower(to?: string) {
    await this.mintFlower(new User('minter').btcFlowerActor, canisterIds.btcflower.local, to);
  }

  async mintETHFlower(to?: string) {
    await this.mintFlower(new User('minter').ethFlowerActor, canisterIds.ethflower.local, to);
  }

  async mintICPFlower(to?: string) {
    await this.mintFlower(new User('minter').icpFlowerActor, canisterIds.icpflower.local, to);
  }

  async mintBTCFlowerGen2(to?: string) {
    await this.mintFlower(new User('minter').btcFlowerGen2Actor, canisterIds.btcflower_gen2.local, to);
  }
}