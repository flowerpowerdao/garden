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

    let btcflowers = await user.btcflowerActor.tokens(user.accountId);
    await user.btcflowerActor.transfer({
      amount: 1n,
      from: { address: user.accountId },
      to: { address: toAccountId(stakingAccount) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.btcflower.local, btcflowers['ok'][0]),
    });

    let ethtokens = await user.ethflowerActor.tokens(user.accountId);
    await user.btcflowerActor.transfer({
      amount: 1n,
      from: { address: user.accountId },
      to: { address: toAccountId(stakingAccount) },
      memo: [],
      notify: false,
      subaccount: [],
      token: tokenIdentifier(canisterIds.btcflower.local, ethtokens['ok'][0]),
    });
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
    let rewards = rewardsForVotingPower(3, totalVotingPower, neuron.prevRewardTime - neuron.createdAt)
    expect(neuron.rewards).toBeGreaterThan(rewards - 2n);
  });

  test('dissolve neuron', async () => {
    let neurons = await user.mainActor.getUserNeurons();
    await user.mainActor.dissolveNeuron(neurons[0].id);
  });

  let curRewards = 0n;
  test('save current rewards', async () => {
    let neurons = await user.mainActor.getUserNeurons();
    await user.mainActor.dissolveNeuron(neurons[0].id);
    curRewards = neurons[0].rewards;
  });

  test('wait for neuron to dissolve', async () => {
    await new Promise(resolve => setTimeout(resolve, 1000 * 15));
  });

  test('check there are no new rewards', async () => {
    let neuron = (await user.mainActor.getUserNeurons())[0];
    expect(neuron.rewards).toBeGreaterThan(curRewards);
  });
});