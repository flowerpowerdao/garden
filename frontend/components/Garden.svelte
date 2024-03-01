<script lang="ts">
  import { setContext } from 'svelte';
  import { authStore, store } from '../store';
  import UnstakedFlower from './UnstakedFlower.svelte';
  import StakedFlower from './StakedFlower.svelte';
  import { Neuron, UserRes } from '../../declarations/main/main.did';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { Collection } from '../types';
  import Rewards from './Rewards.svelte';
  import DisclaimerModal from './DisclaimerModal.svelte';
  import SeedTokenCard from './SeedTokenCard.svelte';

  type Flower = {
    collection: Collection;
    tokenIndex: number;
    neuron?: Neuron;
  };

  let loading = false;
  let gardenLoading = true;
  let inited = false;

  $: isAuthed = $store.actorsAuthed;
  $: if ($store.actorsAuthed && !inited) {
    inited = true;
    load();
  };
  $: if (!$store.actorsAuthed) {
    inited = false;
  };

  let user: UserRes;

  let unstakedBtcFlowers: Flower[] = [];
  let unstakedEthFlowers: Flower[] = [];
  let unstakedIcpFlowers: Flower[] = [];
  let unstakedBtcFlowersGen2: Flower[] = [];

  let unstakedFlowers: Flower[] = [];
  let stakedFlowers: Flower[] = [];

  type RefreshTarget = 'staked' | 'all';

  async function load(refresh = false, target: RefreshTarget = 'all') {
    console.trace(11);
    if (loading) {
      return;
    }

    if (!refresh) {
      loading = true;
      gardenLoading = true;
    }

    let loadUnstakedBtcFlowers = async () => {
      let res = await $store.btcFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedBtcFlowers = Array.from(res.ok).map((tokenIndex) => ({ collection: 'btcFlower' as Collection, tokenIndex }));
      }
    }

    let loadUnstakedEthFlowers = async () => {
      let res = await $store.ethFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedEthFlowers = Array.from(res.ok).map((tokenIndex) => ({ collection: 'ethFlower' as Collection, tokenIndex }));
      }
    }

    let loadUnstakedIcpFlowers = async () => {
      let res = await $store.icpFlowerActor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedIcpFlowers = Array.from(res.ok).map((tokenIndex) => ({ collection: 'icpFlower' as Collection, tokenIndex }));
      }
    }

    let loadUnstakedBtcFlowersGen2 = async () => {
      let res = await $store.btcFlowerGen2Actor.tokens($authStore.accountId);
      if ('ok' in res) {
        unstakedBtcFlowersGen2 = Array.from(res.ok).map((tokenIndex) => ({ collection: 'btcFlowerGen2' as Collection, tokenIndex }));
      }
    }

    let loadStakedFlowers = async () => {
      user = await $store.gardenActor.getCallerUser();

      let stkdFlowers: Flower[] = [];
      for (let neuron of user.neurons) {
        console.log(neuron)
        stkdFlowers.push({
          collection: Object.keys(neuron.flower.collection)[0].replace('BTC', 'btc').replace('ETH', 'eth').replace('ICP', 'icp') as Collection,
          tokenIndex: Number(neuron.flower.tokenIndex),
          neuron: neuron,
        });
      }
      stakedFlowers = [...stkdFlowers];
      console.log(user, stakedFlowers)
    }

    await Promise.all([
      target !== 'staked' && loadUnstakedBtcFlowers(),
      target !== 'staked' && loadUnstakedEthFlowers(),
      target !== 'staked' && loadUnstakedIcpFlowers(),
      target !== 'staked' && loadUnstakedBtcFlowersGen2(),
      loadStakedFlowers(),
    ]);

    unstakedFlowers = [
      ...unstakedBtcFlowers,
      ...unstakedEthFlowers,
      ...unstakedIcpFlowers,
      ...unstakedBtcFlowersGen2,
    ];

    loading = false;
    gardenLoading = false;
  }

  async function refreshGarden(target: RefreshTarget = 'all') {
    await load(true, target);
  }

  setContext('refreshGarden', refreshGarden);
</script>


<div class="py-20 text-4xl text-center">FPDAO Garden</div>

<div class="px-10 pb-40 dark:text-white">
  {#if !isAuthed}
    <div class="text-xl text-center text-gray-500">Connect your wallet to see your garden</div>
    <SeedTokenCard></SeedTokenCard>
  {:else if gardenLoading}
    <div class="flex items-center gap-3 py-10 mt-7 text-3xl"><Loader></Loader> Loading...</div>
  {:else}
    <div class="flex justify-between items-start flex-wrap">
      <div>
        <div class="py-10 text-3xl">Your rewards</div>
        <Rewards {user}></Rewards>
      </div>
      <SeedTokenCard></SeedTokenCard>
    </div>

    <div class="py-10 mt-7 text-3xl">Flowers in your garden</div>
    <div class="flex gap-20 flex-wrap">
      {#each stakedFlowers as flower (flower.collection + flower.tokenIndex)}
        <StakedFlower neuron={flower.neuron}></StakedFlower>
      {:else}
        <div class="text-xl text-gray-500">No flowers in Garden</div>
      {/each}
    </div>

    <div class="py-10 mt-10 text-3xl">Flowers in your wallet</div>
    <div class="flex gap-20 flex-wrap">
      {#each unstakedFlowers as flower (flower.collection + flower.tokenIndex)}
        <UnstakedFlower collection={flower.collection} tokenIndex={flower.tokenIndex}></UnstakedFlower>
      {:else}
        <div class="text-xl text-gray-500">No flowers in your wallet</div>
      {/each}
    </div>
  {/if}
</div>

<DisclaimerModal></DisclaimerModal>