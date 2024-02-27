<script lang="ts">
  import { getContext } from 'svelte';
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import { authStore, store } from '../store';
  import { getCollectionCanisterId, getCollectionDailyRewards, toAccountId, tokenIdentifier } from '../utils';
  import { Collection as CollectionBackend } from 'declarations/main/main.did';
  import { Collection } from '../types';

  export let collection: Collection;
  export let tokenIndex: number;

  let refreshGarden = getContext('refreshGarden') as () => Promise<void>;

  let dailyReward = getCollectionDailyRewards(collection);
  let modalOpen = false;
  let loading = false;
  let success = false;
  let error = '';

  export function toggleModal() {
    modalOpen = !modalOpen;
    loading = false;
    error = '';
  }

  function getCollectionActor() {
    if (collection === 'btcFlower') {
      return $store.btcFlowerActor;
    } else if (collection === 'ethFlower') {
      return $store.ethFlowerActor;
    } else if (collection === 'icpFlower') {
      return $store.icpFlowerActor;
    } else if (collection === 'btcFlowerGen2') {
      return $store.btcFlowerGen2Actor;
    } else {
      throw new Error('Invalid collection');
    }
  }

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

  async function stake() {
    loading = true;

    let collectionActor = getCollectionActor();
    let collections = ['btcFlower', 'ethFlower', 'icpFlower']
    let nonce = 10_000 * collections.indexOf(collection) + tokenIndex;
    let stakeFlower = {
      collection: getCollectionVariant(),
      tokenIndex: BigInt(tokenIndex),
    };
    let stakingAccount = await $store.gardenActor.getStakingAccount(stakeFlower);
    localStorage.setItem(`${collection}-${tokenIndex}-nonce`, nonce.toString());

    console.log('staking account', stakingAccount);

    let res = await collectionActor.transfer({
      from: { principal: $authStore.principal },
      subaccount: [],
      to: { address: toAccountId(stakingAccount) },
      token: tokenIdentifier(getCollectionCanisterId(collection), tokenIndex),
      notify: false,
      amount: 1n,
      memo: [],
    });

    if ('err' in res) {
      error = JSON.stringify(res.err, null, 2);
      return;
    }

    let stakeRes = await $store.gardenActor.stake(stakeFlower);
    if ('err' in stakeRes) {
      error = stakeRes.err;
      return;
    }

    await refreshGarden();

    loading = false;
    modalOpen = false;
  }
</script>

{#if modalOpen}
  <Modal title="Plant Flower" {toggleModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      {#if error}
        <div class="text-red-700 text-xl flex flex-col grow">
          <div>Error</div>
          <div>{error}</div>
        </div>
      {:else if success}
        <div class="text-xl text-green-700">
          Success!
        </div>
      {:else}
        <div class="text-xl flex flex-col gap-4">
          <div>You are about to plant your flower.</div>
          <div>Planted flower will give you {dailyReward} SEED tokens every day.</div>
          <div>If you decide to unstake the flower you have to wait 30 day before you can withdraw the flower.</div>
        </div>
        <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading} on:click={stake}>
          {#if loading}
            <Loader {loading}></Loader>
          {:else}
            Plant!
          {/if}
        </Button>
      {/if}
    </div>
  </Modal>
{/if}