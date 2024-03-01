import { describe, test, expect } from 'vitest';
import { execSync } from 'child_process';
import { User } from './user';
import { rewardsForNeuron, rewardsForUser, toAccountId, tokenIdentifier } from './utils';
import canisterIds from '../.dfx/local/canister_ids.json';
import { Collection as CollectionBackend } from '../declarations/main/main.did';

describe('staking', () => {
  let agent = new User;
  let btcStakeFlower : { collection: CollectionBackend, tokenIndex: bigint };
  let ethStakeFlower : { collection: CollectionBackend, tokenIndex: bigint };
  let icpStakeFlower : { collection: CollectionBackend, tokenIndex: bigint };

  test('deploy', async () => {
    // execSync('npm run deploy');
    execSync('npm run deploy:main');
  });

  test('should return same staking account for the same flower', async () => {
    let stakeFlower = {
      collection: { BTCFlowerGen2: null },
      tokenIndex: BigInt(23),
    };
    let stakingAccount1 = await agent.mainActor.getStakingAccount(stakeFlower);
    let stakingAccount2 = await agent.mainActor.getStakingAccount(stakeFlower);
    expect(stakingAccount1).toEqual(stakingAccount2);
  });

  test('obtain unique staking accounts for different flowers', async () => {
    let set = new Set;
    let flowerCount = 111;
    let collections = ['BTCFlower', 'ETHFlower', 'ICPFlower', 'BTCFlowerGen2'];
    for (let collection of collections) {
      for (let i = 0; i < flowerCount; i++) {
        let stakeFlower = {
          collection: { [collection]: null } as CollectionBackend,
          tokenIndex: BigInt(i),
        };
        let stakingAccount = await agent.mainActor.getStakingAccount(stakeFlower);
        set.add(stakingAccount);
      }
    }
    expect(set.size).toBe(flowerCount * collections.length);
  });

  test('transfer btc/eth/icp flowers to staking account', async () => {
    await agent.mintBTCFlower();
    await agent.mintETHFlower();
    await agent.mintICPFlower();

    let btcFlowers = await agent.btcFlowerActor.tokens(agent.accountId);
    btcStakeFlower = {
      collection: { BTCFlower: null },
      tokenIndex: BigInt(btcFlowers['ok'][0]),
    };
    let stakingAccount1 = await agent.mainActor.getStakingAccount(btcStakeFlower);
    let res1 = await agent.btcFlowerActor.transfer({
      amount: 1n,
      from: { address: agent.accountId },
      to: { address: toAccountId(stakingAccount1) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.btcflower.local, btcStakeFlower.tokenIndex),
    });
    expect(res1).toHaveProperty('ok');

    let ethFlowers = await agent.ethFlowerActor.tokens(agent.accountId);
    ethStakeFlower = {
      collection: { ETHFlower: null },
      tokenIndex: BigInt(ethFlowers['ok'][0]),
    };
    let stakingAccount2 = await agent.mainActor.getStakingAccount(ethStakeFlower);
    let res2 = await agent.ethFlowerActor.transfer({
      amount: 1n,
      from: { address: agent.accountId },
      to: { address: toAccountId(stakingAccount2) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.ethflower.local, ethStakeFlower.tokenIndex),
    });
    expect(res2).toHaveProperty('ok');

    let icpFlowers = await agent.icpFlowerActor.tokens(agent.accountId);
    icpStakeFlower = {
      collection: { ICPFlower: null },
      tokenIndex: BigInt(icpFlowers['ok'][0]),
    };
    let stakingAccount3 = await agent.mainActor.getStakingAccount(icpStakeFlower);
    let res3 = await agent.icpFlowerActor.transfer({
      amount: 1n,
      from: { address: agent.accountId },
      to: { address: toAccountId(stakingAccount3) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.icpflower.local, icpStakeFlower.tokenIndex),
    });
    expect(res3).toHaveProperty('ok');
  });

  test('stake 3 flowers', async () => {
    expect((await agent.mainActor.getCallerUser()).neurons).toHaveLength(0);

    await Promise.all([
      (async () => {
        let res1 = await agent.mainActor.stake(btcStakeFlower);
        expect(res1).toHaveProperty('ok');
      })(),
      (async () => {
        let res2 = await agent.mainActor.stake(ethStakeFlower);
        expect(res2).toHaveProperty('ok');
      })(),
      (async () => {
        let res3 = await agent.mainActor.stake(icpStakeFlower);
        expect(res3).toHaveProperty('ok');
      })(),
    ]);
    let user = await agent.mainActor.getCallerUser();
    let neurons = user.neurons;

    expect(user.neurons).toHaveLength(3);

    // inconsistent because of short rewards period
    // expect(neurons[2].prevRewardTime).toBe(neurons[2].stakedAt);
    // expect(neurons[2].totalRewards).toBe(0n);
  });

  test('get user neurons', async () => {
    let neurons = (await agent.mainActor.getCallerUser()).neurons;
    expect(neurons).toHaveLength(3);
    expect(neurons[0].flower).toEqual(btcStakeFlower);
    expect(neurons[1].flower).toEqual(ethStakeFlower);
    expect(neurons[2].flower).toEqual(icpStakeFlower);
  });

  test('wait for rewards', async () => {
    await new Promise(resolve => setTimeout(resolve, 1000 * 10));
  });

  test('check rewards', async () => {
    let user = await agent.mainActor.getCallerUser();
    let rewards = rewardsForUser(user);

    for (let neuron of user.neurons) {
      expect(neuron.totalRewards).toBeGreaterThanOrEqual(rewardsForNeuron(neuron) - 1n);
      expect(neuron.totalRewards).toBeLessThanOrEqual(rewardsForNeuron(neuron) + 1n);
      expect(neuron.totalRewards).not.toBe(rewardsForNeuron(neuron) + 10n);
    }

    rewards += rewards * 15n / 100n; // trilogy bonus
    expect(user.rewards).toBeGreaterThan(0n);
    expect(user.rewards).toBeGreaterThanOrEqual(rewards - 2n);
    expect(user.rewards).toBeLessThanOrEqual(rewards + 2n);
  });

  test('try to disburse not dissolving neuron', async () => {
    let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
    let res = await agent.mainActor.disburseNeuron(neuron.id, agent.account);
    expect(res).toEqual({ err: "neuron is not dissolved yet" });
  });

  let oldTotalRewards = 0n;

  describe('dissolve', () => {
    test('dissolve neuron', async () => {
      let neurons = (await agent.mainActor.getCallerUser()).neurons;
      expect(await agent.mainActor.dissolveNeuron(neurons[0].id)).toHaveProperty('ok');
    });

    test('check neuron\'s dissolve state', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      expect(neuron.dissolveState).toHaveProperty('DissolveTimestamp');
    });

    test('save current rewards', async () => {
      let neurons = (await agent.mainActor.getCallerUser()).neurons;
      oldTotalRewards = neurons[0].totalRewards;
    });

    test('try to disburse dissolving but not dissolved neuron', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      let res = await agent.mainActor.disburseNeuron(neuron.id, agent.account);
      expect(res).toEqual({err: "neuron is not dissolved yet"});
    });

    test('wait for neuron to dissolve', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 15));
    });

    test('check there are no new rewards for neuron', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      expect(neuron.totalRewards).toBe(oldTotalRewards);
    });
  });

  test('withdraw rewards', async () => {
    let agent2 = new User;
    let user = await agent.mainActor.getCallerUser();
    let res = await agent.mainActor.claimRewards(agent2.account);
    expect(res).toHaveProperty('ok');
    expect(await agent.seedActor.icrc1_balance_of(agent2.account)).toBe(user.rewards);

    user = await agent.mainActor.getCallerUser();
    expect(user.rewards).toBe(0n);
  });

  describe('restake', () => {
    test('restake neuron', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      let res = await agent.mainActor.restake(neuron.id);
      expect(res).toHaveProperty('ok');
    });

    test('wait for rewards', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 7));
    });

    test('check rewards', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      let rewards = rewardsForNeuron(neuron);
      expect(neuron.totalRewards).toBeGreaterThan(oldTotalRewards + rewards - 2n);
      expect(neuron.totalRewards).toBeLessThan(oldTotalRewards + rewards + 2n);
    });
  });

  describe('dissolve again', () => {
    test('dissolve neuron', async () => {
      let neurons = (await agent.mainActor.getCallerUser()).neurons;
      expect(await agent.mainActor.dissolveNeuron(neurons[0].id)).toHaveProperty('ok');
    });

    let oldTotalRewards2 = 0n;
    test('save current rewards', async () => {
      let neurons = (await agent.mainActor.getCallerUser()).neurons;
      oldTotalRewards2 = neurons[0].totalRewards;
    });

    test('wait for neuron to dissolve', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 15));
    });

    test('check there are no new rewards', async () => {
      let neuron = ((await agent.mainActor.getCallerUser()).neurons)[0];
      expect(neuron.totalRewards).toBe(oldTotalRewards2);
    });
  });

  test('disburse neuron', async () => {
    let user = await agent.mainActor.getCallerUser();
    let neuron = user.neurons[0];

    // disburse neuron
    let res = await agent.mainActor.disburseNeuron(neuron.id, agent.account);
    expect(res).toHaveProperty('ok');

    // check if flower is transferred back to user
    expect((await agent.btcFlowerActor.tokens(agent.accountId))['ok'][0]).toBe(Number(neuron.flower.tokenIndex));
  });

  test('neuron should be deleted', async () => {
    let neurons = (await agent.mainActor.getCallerUser()).neurons;
    expect(neurons.length).toBe(2);
  });
});