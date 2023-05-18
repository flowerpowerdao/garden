import { Actor, AnonymousIdentity } from '@dfinity/agent';
import { AccountIdentifier } from '@dfinity/nns';
import { Principal } from '@dfinity/principal';
import { Secp256k1KeyIdentity } from '@dfinity/identity-secp256k1';

import { generateIdentity } from './generate-identity';
import { createAgent } from './create-agent';
import { IDL } from '@dfinity/candid';

export type Subaccount = Uint8Array | number[];
export type Account = {
  'owner': Principal,
  'subaccount': [] | [Subaccount],
};

export class FakeUser {
  identity: Secp256k1KeyIdentity | AnonymousIdentity;
  principal: Principal;
  account: Account;
  accountId: string;

  constructor(seed?: string) {
    this.identity = generateIdentity(seed);
    this.principal = this.identity.getPrincipal();
    this.account = {owner: this.principal, subaccount: []};
    this.accountId = AccountIdentifier.fromPrincipal({principal: this.principal}).toHex();
  }

  createActor<T>(idlFactory: IDL.InterfaceFactory, canisterId: string) {
    return Actor.createActor<T>(idlFactory, {
      agent: createAgent(this.identity),
      canisterId: canisterId,
    });
  }
}