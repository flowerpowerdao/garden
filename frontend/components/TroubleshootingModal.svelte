<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { getContext } from 'svelte';

  import { store } from '../store';
  import { getCollectionName } from '../utils';
  import { Collection as CollectionBackend, Flower } from 'declarations/main/main.did';
  import { Collection } from '../types';

  let collections: Collection[] = ['btcFlower', 'ethFlower', 'icpFlower', 'btcFlowerGen2'];
  let collection: Collection;
  let tokenNumber: number;

  function getCollectionVariant(): CollectionBackend {
    if (collection === 'btcFlower') {
      return { BTCFlower: null };
    } else if (collection === 'ethFlower') {
      return { ETHFlower: null };
    } else if (collection === 'icpFlower') {
      return { ICPFlower: null };
    } else if (collection === 'btcFlowerGen2') {
      return { BTCFlowerGen2: null };
    } else {
      throw new Error('Invalid collection');
    }
  }

  let refreshGarden = getContext('refreshGarden') as (target: string) => Promise<void>;

  let modalOpen = false;
  let loading = false;
  let success = false;
  let error = '';

  export function toggleModal() {
    modalOpen = !modalOpen;
    loading = false;
    error = '';
  }

  async function withdrawStuckFlower() {
    loading = true;
    error = '';

    let flower: Flower = { collection: getCollectionVariant(), tokenIndex: BigInt(tokenNumber - 1) };
    let res = await $store.gardenActor.withdrawStuckFlower(flower);
    if ('err' in res) {
      error = res.err;
      loading = false;
      return;
    }

    await refreshGarden('all');

    success = true;
    loading = false;
  }
</script>

{#if modalOpen}
  <Modal title="Troubleshooting" {toggleModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      Lost your flower during planting?<br>
      Use this tool to withdraw it back to your wallet.
      <br>
      <br>
      <div class="text-xl flex flex-col gap-4">
        <div>Collection:</div>
        <select class="border-2 border-black p-2" bind:value={collection}>
          {#each collections as collectn}
            <option value={collectn}>{getCollectionName(collectn)}</option>
          {/each}
        </select>
        <div>Token number:</div>
        <input class="border-2 border-black p-2" type="number" min="1" max="2024" bind:value={tokenNumber} />
      </div>

      {#if error}
        <div class="text-red-700 text-xl flex flex-col grow">
          <div>{error}</div>
        </div>
      {:else if success}
        <div class="text-xl text-green-700">
          Flower is withdrawn to your wallet!
        </div>
      {/if}

      <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading} on:click={withdrawStuckFlower}>
        {#if loading}
          <Loader {loading}></Loader>
        {:else}
          Withdraw
        {/if}
      </Button>
    </div>
  </Modal>
{/if}