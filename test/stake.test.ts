import { describe, test, expect } from 'vitest';
import { execSync } from 'child_process';
import { User } from './user';
import { rewardsForVotingPower, toAccountId, tokenIdentifier } from './utils';
import canisterIds from '../.dfx/local/canister_ids.json';

describe('staking', () => {
  let user = new User;
  let nonce = 1;
  let totalVotingPower = 3;

  test('deploy', async () => {
    // execSync('npm run deploy');
    execSync('npm run deploy:main');
  });

  test('should return same staking account for the same nonce', async () => {
    let stakingAccount1 = await user.mainActor.getStakingAccount(23);
    let stakingAccount2 = await user.mainActor.getStakingAccount(23);
    expect(stakingAccount1).toEqual(stakingAccount2);
  });

  test('obtain unique staking accounts for random nonce', async () => {
    let set = new Set;
    for (let i = 0; i < 10; i++) {
      let stakingAccount = await user.mainActor.getStakingAccount((Math.random() * (2 ** 16 - 1)) |0);
      set.add(stakingAccount);
    }
    expect(set.size).toBe(10);
  });

  test('transfer btc flower and eth flower to staking account', async () => {
    let stakingAccount = await user.mainActor.getStakingAccount(nonce);
    await user.mintBTCFlower();
    await user.mintETHFlower();

    let btcFlowers = await user.btcFlowerActor.tokens(user.accountId);
    let res1 = await user.btcFlowerActor.transfer({
      amount: 1n,
      from: { address: user.accountId },
      to: { address: toAccountId(stakingAccount) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.btcflower.local, btcFlowers['ok'][0]),
    });
    expect(res1).toHaveProperty('ok');

    let ethFlowers = await user.ethFlowerActor.tokens(user.accountId);
    let res2 = await user.ethFlowerActor.transfer({
      amount: 1n,
      from: { address: user.accountId },
      to: { address: toAccountId(stakingAccount) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.ethflower.local, ethFlowers['ok'][0]),
    });
    expect(res2).toHaveProperty('ok');
  });

  test('stake neuron', async () => {
    expect(await user.mainActor.getUserNeurons()).toHaveLength(0);
    let res = await user.mainActor.stake(nonce);
    expect(res).toHaveProperty('ok');
    expect(await user.mainActor.getUserNeurons()).toHaveLength(1);
  });

  test('get user neurons', async () => {
    let neurons = await user.mainActor.getUserNeurons();
    expect(neurons).toHaveLength(1);
  });

  test('wait for rewards', async () => {
    await new Promise(resolve => setTimeout(resolve, 1000 * 5));
  });

  test('check rewards', async () => {
    let neuron = (await user.mainActor.getUserNeurons())[0];
    let rewards = rewardsForVotingPower(3, totalVotingPower, neuron.prevRewardTime - neuron.stakedAt)
    expect(neuron.rewards).toBeGreaterThan(rewards - 2n);
  });

  test('try to disburse not dissolving neuron', async () => {
    let neuron = (await user.mainActor.getUserNeurons())[0];
    let res = await user.mainActor.disburseNeuron(neuron.id, user.account);
    expect(res).toEqual({ err: "neuron is not dissolved yet" });
  });

  describe('dissolve', () => {
    test('dissolve neuron', async () => {
      let neurons = await user.mainActor.getUserNeurons();
      expect(await user.mainActor.dissolveNeuron(neurons[0].id)).toHaveProperty('ok');
    });

    test('check neuron\'s dissolve state', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      expect(neuron.dissolveState).toHaveProperty('DissolveTimestamp');
    });

    let curRewards = 0n;
    test('save current rewards', async () => {
      let neurons = await user.mainActor.getUserNeurons();
      curRewards = neurons[0].rewards;
    });

    test('try to disburse dissolving but not dissolved neuron', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      let res = await user.mainActor.disburseNeuron(neuron.id, user.account);
      expect(res).toEqual({err: "neuron is not dissolved yet"});
    });

    test('wait for neuron to dissolve', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 15));
    });

    test('check there are no new rewards', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      expect(neuron.rewards).toBe(curRewards);
    });
  });

  test('withdraw rewards', async () => {
    let newUser = new User;
    let neuron = (await user.mainActor.getUserNeurons())[0];
    let res = await user.mainActor.claimRewards(neuron.id, newUser.account);
    expect(res).toHaveProperty('ok');
    expect(await user.seedActor.icrc1_balance_of(newUser.account)).toBe(neuron.rewards);

    neuron = (await user.mainActor.getUserNeurons())[0];
    expect(neuron.rewards).toBe(0n);
  });

  describe('restake', () => {
    test('restake neuron', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      let res = await user.mainActor.restake(neuron.id);
      expect(res).toHaveProperty('ok');
    });

    test('wait for rewards', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 5));
    });

    test('check rewards', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      let rewards = rewardsForVotingPower(3, totalVotingPower, neuron.prevRewardTime - neuron.stakedAt);
      expect(neuron.rewards).toBeGreaterThan(rewards - 2n);
    });
  });

  describe('dissolve again', () => {
    test('dissolve neuron', async () => {
      let neurons = await user.mainActor.getUserNeurons();
      expect(await user.mainActor.dissolveNeuron(neurons[0].id)).toHaveProperty('ok');
    });

    let curRewards = 0n;
    test('save current rewards', async () => {
      let neurons = await user.mainActor.getUserNeurons();
      curRewards = neurons[0].rewards;
    });

    test('wait for neuron to dissolve', async () => {
      await new Promise(resolve => setTimeout(resolve, 1000 * 15));
    });

    test('check there are no new rewards', async () => {
      let neuron = (await user.mainActor.getUserNeurons())[0];
      expect(neuron.rewards).toBe(curRewards);
    });
  });

  test('disburse neuron', async () => {
    let neuron = (await user.mainActor.getUserNeurons())[0];
    let res = await user.mainActor.disburseNeuron(neuron.id, user.account);
    expect(res).toHaveProperty('ok');

    expect(await user.seedActor.icrc1_balance_of(user.account)).toBe(neuron.rewards);
    expect((await user.btcFlowerActor.tokens(user.accountId))['ok'][0]).toBe(Number([neuron.flowers.find(f => 'BTCFlower' in f.collection)?.tokenIndex]));
    expect((await user.ethFlowerActor.tokens(user.accountId))['ok'][0]).toBe(Number([neuron.flowers.find(f => 'ETHFlower' in f.collection)?.tokenIndex]));
  });

  test('neuron should be deleted', async () => {
    let neurons = await user.mainActor.getUserNeurons();
    expect(neurons.length).toBe(0);
  });
});