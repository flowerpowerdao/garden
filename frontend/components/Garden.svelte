<script lang="ts">
  import { setContext } from 'svelte';
  import { authStore, store } from '../store';
  import UnstakedFlower from './UnstakedFlower.svelte';
  import StakedFlower from './StakedFlower.svelte';
  import { Neuron, UserRes } from '../../declarations/main/main.did';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { Collection } from '../types';
  import Rewards from './Rewards.svelte';

  type Flower = {
    collection: Collection;
    tokenIndex: number;
    neuron?: Neuron;
  };

  let loading = false;
  let gardenLoading = true;
  $: isAuthed = $authStore.isAuthed;

  let user: UserRes;
  let unstakedFlowers: Flower[] = [];
  let stakedFlowers: Flower[] = [];

  $: if ($authStore.isAuthed) {
    load();
  };

  async function load() {
    if (loading) {
      return;
    }
    loading = true;
    gardenLoading = true;

    unstakedFlowers = [];
    stakedFlowers = [];
    let loadUnstakedBtcFlowers = async () => {
      let res = await $store.btcFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'btcFlower' as Collection, tokenIndex }))];
      }
    }

    let loadUnstakedEthFlowers = async () => {
      let res = await $store.ethFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'ethFlower' as Collection, tokenIndex }))];
      }
    }

    let loadUnstakedIcpFlowers = async () => {
      let res = await $store.icpFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'icpFlower' as Collection, tokenIndex }))];
      }
    }

    let loadUnstakedBtcFlowersGen2 = async () => {
      let res = await $store.btcFlowerGen2Actor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'btcFlowerGen2' as Collection, tokenIndex }))];
      }
    }

    let loadStakedFlowers = async () => {
      user = await $store.gardenActor.getCallerUser();
      for (let neuron of user.neurons) {
        console.log(neuron)
        stakedFlowers.push({
          collection: Object.keys(neuron.flower.collection)[0].replace('BTC', 'btc').replace('ETH', 'eth').replace('ICP', 'icp') as Collection,
          tokenIndex: Number(neuron.flower.tokenIndex),
          neuron: neuron,
        });
      }
      stakedFlowers = [...stakedFlowers];
      console.log(user, stakedFlowers)
    }

    await Promise.all([
      loadUnstakedBtcFlowers(),
      loadUnstakedEthFlowers(),
      loadUnstakedIcpFlowers(),
      loadUnstakedBtcFlowersGen2(),
      loadStakedFlowers(),
    ]);

    loading = false;
    gardenLoading = false;
  }

  setContext('refreshGarden', load);
</script>


<div class="py-20 text-4xl text-center">FPDAO Garden</div>

<div class="px-10 pb-40">
  {#if !isAuthed}
    <div class="text-xl text-gray-500">Connect your wallet to see your garden</div>
  {:else if gardenLoading}
    <div class="flex items-center gap-3 py-10 mt-7 text-3xl"><Loader></Loader> Loading...</div>
  {:else}
    <div class="py-10 text-3xl">Your rewards</div>
    <div class="flex gap-20 flex-wrap">
      <Rewards {user}></Rewards>
    </div>

    <div class="py-10 mt-7 text-3xl">Flowers in your garden</div>
    <div class="flex gap-20 flex-wrap">
      {#each stakedFlowers as flower}
        <StakedFlower neuron={flower.neuron}></StakedFlower>
      {:else}
        <div class="text-xl text-gray-500">No flowers in Garden</div>
      {/each}
    </div>

    <div class="py-10 mt-7 text-3xl">Flowers in your wallet</div>
    <div class="flex gap-20 flex-wrap">
      {#each unstakedFlowers as flower}
        <UnstakedFlower collection={flower.collection} tokenIndex={flower.tokenIndex}></UnstakedFlower>
      {:else}
        <div class="text-xl text-gray-500">No flowers in your wallet</div>
      {/each}
    </div>
  {/if}
</div>