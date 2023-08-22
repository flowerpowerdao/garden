<script lang="ts">
  import { authStore, store } from '../store';
  import UnstakedFlower from './UnstakedFlower.svelte';

  let loading = false;
  let btcFlowerTokens: Uint32Array | number[] = [];
  let ethFlowerTokens: Uint32Array | number[] = [];
  let icpFlowerTokens: Uint32Array | number[] = [];

  $: if ($authStore.isAuthed) {
    load();
  };

  async function load() {
    if (loading) {
      return;
    }
    loading = true;
    let res = await $store.btcFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      btcFlowerTokens = res.ok;
    }

    res = await $store.ethFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      ethFlowerTokens = res.ok;
    }

    res = await $store.icpFlowerActor.tokens($authStore.accountId);
    if ('ok' in res) {
      icpFlowerTokens = res.ok;
    }

    let r = await $store.gardenActor.getUserNeurons();
    console.log(r)
  }
</script>


<div class="py-20 text-4xl text-center">FPDAO Garden</div>

<div class="px-10">
  <div class="py-10 text-3xl">Flowers in your wallet</div>
  <div class="flex gap-20 flex-wrap">
    {#each btcFlowerTokens as token}
      <UnstakedFlower collection="btcFlower" tokenIndex={token}></UnstakedFlower>
    {/each}
    {#each ethFlowerTokens as token}
      <UnstakedFlower collection="ethFlower" tokenIndex={token}></UnstakedFlower>
    {/each}
    {#each icpFlowerTokens as token}
      <UnstakedFlower collection="icpFlower" tokenIndex={token}></UnstakedFlower>
    {/each}
  </div>
</div>