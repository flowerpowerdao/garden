import { Principal } from "@dfinity/principal";
import { expect } from "vitest";
import { User } from "./user";

import canisterIds from '../.dfx/local/canister_ids.json';
import { AccountIdentifier, SubAccount } from '@dfinity/ledger-icp';

import {Account} from '../declarations/icrc1/icrc1.did';
import {Neuron, UserRes} from '../declarations/main/main.did';

export function feeOf(amount: bigint, fee: bigint) {
  return amount * fee / 100_000n;
}

export function applyFees(amount: bigint, fees: bigint[]) {
  let result = amount;
  for (let fee of fees) {
    result -= amount * fee / 100_000n;
  }
  return result;
}

// export async function buyFromSale(user: User) {
//   let settings = await user.mainActor.salesSettings(user.accountId);
//   let res = await user.mainActor.reserve(settings.price, 1n, user.accountId, new Uint8Array);

//   expect(res).toHaveProperty('ok');

//   if ('ok' in res) {
//     let paymentAddress = res.ok[0];
//     let paymentAmount = res.ok[1];
//     expect(paymentAddress.length).toBe(64);
//     expect(paymentAmount).toBe(settings.price);

//     await user.sendICP(paymentAddress, paymentAmount);
//     let retrieveRes = await user.mainActor.retrieve(paymentAddress);
//     expect(retrieveRes).toHaveProperty('ok');
//   }
// }

// export async function checkTokenCount(user: User, count: number) {
//   let tokensRes = await user.mainActor.tokens(user.accountId);
//   expect(tokensRes).toHaveProperty('ok');
//   if ('ok' in tokensRes) {
//     expect(tokensRes.ok.length).toBe(count);
//     if (count > 0) {
//       let tokenIndex = tokensRes.ok.at(-1);
//       expect(tokenIndex).toBeGreaterThan(0);
//     }
//   }
// }

// https://github.com/Toniq-Labs/ext-cli/blob/main/src/utils.js#L62-L66
export let to32bits = (num) => {
  let b = new ArrayBuffer(4);
  new DataView(b).setUint32(0, num);
  return Array.from(new Uint8Array(b));
}

// https://github.com/Toniq-Labs/ext-cli/blob/main/src/extjs.js#L20-L45
export let tokenIdentifier = (canisterId, index) => {
  let padding = Buffer.from("\x0Atid");
  let array = new Uint8Array([
      ...padding,
      ...Principal.fromText(canisterId).toUint8Array(),
      ...to32bits(Number(index)),
  ]);
  return Principal.fromUint8Array(array).toText();
};

export let toAccount = (address: string) => {
  return { account: AccountIdentifier.fromHex(address).toNumbers() };
}

export let toAccountId = (account: Account) => {
  if (account.subaccount[0]) {
    let sa = account.subaccount[0];
    return AccountIdentifier.fromPrincipal({
      principal: account.owner,
      subAccount: sa ? {
        toUint8Array: () => Uint8Array.from(sa)
      } as SubAccount : undefined,
    }).toHex();
  }
  else {
    return AccountIdentifier.fromPrincipal({principal: account.owner}).toHex();
  }
};

export function rewardsForNeuron(neuron: Neuron) {
  let elapsedTime = neuron.prevRewardTime - neuron.stakedAt;
  if (!elapsedTime) {
    return 0n;
  }
  let DAY = 86_400_000_000_000n;
  let BIG_NUMBER = 1_000_000_000_000_000_000_000n;
  let dailyRewards = 'BTCFlower' in neuron.flower.collection ? 200000000n : 50000000n;
  let rewards = BIG_NUMBER * dailyRewards * elapsedTime / DAY / BIG_NUMBER;
  return rewards;
}

export function rewardsForUser(user: UserRes) {
  let rewards = 0n;
  for (let neuron of user.neurons) {
    rewards += rewardsForNeuron(neuron);
  }
  return rewards;
}