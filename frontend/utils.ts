import { Principal } from "@dfinity/principal";
import { AccountIdentifier, SubAccount } from "@dfinity/nns";
import { Account } from '../declarations/icrc1/icrc1.did';
import { Neuron } from '../declarations/main/main.did';
import { btcFlowerCanisterId, ethFlowerCanisterId, icpFlowerCanisterId } from './canister-ids';
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

export let getTokenName = (collection: 'btcFlower' | 'ethFlower' | 'icpFlower', tokenIndex: number) => {
  let collectionName = '';
  if (collection === 'btcFlower') {
    collectionName = `BTC Flower`;
  } else if (collection === 'ethFlower') {
    collectionName = `ETH Flower`;
  } else if (collection === 'icpFlower') {
    collectionName = `ICP Flower`;
  }
  return `${collectionName} #${tokenIndex + 1}`;
};

export let getCollectionCanisterId = (collection: 'btcFlower' | 'ethFlower' | 'icpFlower') => {
  let canisterId = '';
  if (collection === 'btcFlower') {
    canisterId = btcFlowerCanisterId;
  } else if (collection === 'ethFlower') {
    canisterId = ethFlowerCanisterId;
  } else if (collection === 'icpFlower') {
    canisterId = icpFlowerCanisterId;
  }
  return canisterId;
};

export let getNeuronCollection = (neuron: Neuron): Collection => {
  return Object.keys(neuron.flowers[0].collection)[0].replace('BTC', 'btc').replace('ETH', 'eth').replace('ICP', 'icp') as Collection;
}

export let getNeuronTokenIndex = (neuron: Neuron): number => {
  return Number(neuron.flowers[0].tokenIndex);
}