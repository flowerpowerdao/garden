import { FakeUser } from './utils/fake-user';
import canisterIds from '../.dfx/local/canister_ids.json';

import { idlFactory as idlFactoryMain } from '../declarations/main/index.js';
import { _SERVICE as _SERVICE_MAIN } from '../declarations/main/main.did';

import { idlFactory as idlFactorySeed } from '../declarations/icrc1/index.js';
import { _SERVICE as _SERVICE_SEED } from '../declarations/icrc1/icrc1.did';


export class User extends FakeUser {
  mainActor = this.createActor<_SERVICE_MAIN>(idlFactoryMain, canisterIds.main.local);
  seedActor = this.createActor<_SERVICE_SEED>(idlFactorySeed, canisterIds.seed.local);
}