<script lang="ts">
  import { setContext } from 'svelte';
  import { authStore, store } from '../store';
  import UnstakedFlower from './UnstakedFlower.svelte';
  import StakedFlower from './StakedFlower.svelte';
  import { Neuron } from 'declarations/main/main.did';

  type Collection = 'btcFlower' | 'ethFlower' | 'icpFlower';
  type Flower = {
    collection: Collection;
    tokenIndex: number;
    neuron?: Neuron;
  };

  let loading = false;

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

    unstakedFlowers = [];
    stakedFlowers = [];

    let res = await $store.btcFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'btcFlower' as Collection, tokenIndex }))];
    }

    res = await $store.ethFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'ethFlower' as Collection, tokenIndex }))];
    }

    res = await $store.icpFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      unstakedFlowers = [...unstakedFlowers, ...Array.from(res.ok).map((tokenIndex) => ({ collection: 'icpFlower' as Collection, tokenIndex }))];
    }

    let userNeurons = await $store.gardenActor.getUserNeurons();
    for (let neuron of userNeurons) {
      for (let flower of neuron.flowers) {
        console.log(neuron)
        stakedFlowers.push({
          collection: Object.keys(flower.collection)[0].replace('BTC', 'btc').replace('ETH', 'eth').replace('ICP', 'icp') as Collection,
          tokenIndex: Number(flower.tokenIndex),
          neuron: neuron,
        });
      }
    }
    stakedFlowers = [...stakedFlowers];
    console.log(userNeurons, stakedFlowers)
    loading = false;
  }

  setContext('refreshGarden', load);
</script>


<div class="py-20 text-4xl text-center">FPDAO Garden</div>

<div class="px-10 pb-40">
  <div class="py-10 text-3xl">Unstaked Flowers</div>
  <div class="flex gap-20 flex-wrap">
    {#each unstakedFlowers as flower}
      <UnstakedFlower collection={flower.collection} tokenIndex={flower.tokenIndex}></UnstakedFlower>
    {/each}
  </div>

  <div class="py-10 mt-7 text-3xl">Staked Flowers</div>
  <div class="flex gap-20 flex-wrap">
    {#each stakedFlowers as flower}
      <StakedFlower collection={flower.collection} tokenIndex={flower.tokenIndex} neuron={flower.neuron}></StakedFlower>
    {/each}
  </div>
</div>