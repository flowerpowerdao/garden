import { Principal } from "@dfinity/principal";
import { AccountIdentifier, SubAccount } from '@dfinity/ledger-icp';
import { Account } from '../declarations/icrc1/icrc1.did';
import { Neuron } from '../declarations/main/main.did';
import { btcFlowerCanisterId, ethFlowerCanisterId, icpFlowerCanisterId, btcFlowerGen2CanisterId } from './canister-ids';
import { Collection } from './types';

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
      ...to32bits(index),
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

export function rewardsForVotingPower(votingPower: number | bigint, totalVotingPower: number | bigint, elapsedTime: bigint) {
  let totalRewardsPerYear = 1_000_000_00000000n;
  let YEAR = 86_400_000_000_000n * 365n;
  let BIG_NUMBER = 1_000_000_000_000_000_000_000n;
  let rewardsForElapsedTime = BIG_NUMBER * totalRewardsPerYear / YEAR * elapsedTime / BIG_NUMBER;
  let rewards = BIG_NUMBER * BigInt(votingPower) / BigInt(totalVotingPower) * rewardsForElapsedTime / BIG_NUMBER;
  return rewards;
}

export let getCollectionName = (collection: Collection) => {
  if (collection === 'btcFlower') {
    return `BTC Flower`;
  } else if (collection === 'ethFlower') {
    return `ETH Flower`;
  } else if (collection === 'icpFlower') {
    return `ICP Flower`;
  } else if (collection === 'btcFlowerGen2') {
    return `BTC Flower Gen 2.0`;
  }
};

export let getTokenName = (collection: Collection, tokenIndex: number) => {
  return `${getCollectionName(collection)} #${tokenIndex + 1}`;
};

export let getCollectionCanisterId = (collection: Collection) => {
  let canisterId = '';
  if (collection === 'btcFlower') {
    canisterId = btcFlowerCanisterId;
  } else if (collection === 'ethFlower') {
    canisterId = ethFlowerCanisterId;
  } else if (collection === 'icpFlower') {
    canisterId = icpFlowerCanisterId;
  } else if (collection === 'btcFlowerGen2') {
    canisterId = btcFlowerGen2CanisterId;
  }
  return canisterId;
};

export let getNeuronCollection = (neuron: Neuron): Collection => {
  return Object.keys(neuron.flower.collection)[0].replace('BTC', 'btc').replace('ETH', 'eth').replace('ICP', 'icp') as Collection;
}

export let getNeuronTokenIndex = (neuron: Neuron): number => {
  return Number(neuron.flower.tokenIndex);
}

export let getCollectionDailyRewards = (collection: Collection): number => {
  return applyHalvings(collection === 'btcFlower' ? 2 : 0.5);
}

let halvings = [
  1748131200000,
  1779667200000,
  1811203200000,
  1842825600000,
  Infinity,
]

export let applyHalvings = (rewards: number): number => {
  let halvingIndex = halvings.findIndex(h => Date.now() < h);
  return rewards / 2 ** halvingIndex;
}