import { AnonymousIdentity } from '@dfinity/agent';
import { Secp256k1KeyIdentity } from '@dfinity/identity-secp256k1';

// generate random identity
// use seed to generate deterministic identity
export let generateIdentity = (seed?: string) => {
   if (seed !== undefined) {
      return Secp256k1KeyIdentity.generate(Buffer.from([...Buffer.from(seed, 'utf8'), ...Array(32).fill(0)].slice(0, 32)));
   }
   else if (seed === '' || seed === null) {
      return new AnonymousIdentity;
   }
   return Secp256k1KeyIdentity.generate();
}