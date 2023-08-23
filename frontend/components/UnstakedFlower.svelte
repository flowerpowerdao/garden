<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import FlowerPreview from './FlowerPreview.svelte';
  import { authStore, store } from '../store';
  import { getCollectionCanisterId, toAccountId, tokenIdentifier } from '../utils';
  import { getContext } from 'svelte';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;

  let refreshGarden = getContext('refreshGarden') as () => Promise<void>;

  let loading = false;
  let success = false;
  let openModal = false;
  let error = '';

  function toggleModal() {
    openModal = !openModal;
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
    } else {
      throw new Error('Invalid collection');
    }
  }

  async function stake() {
    loading = true;

    let collectionActor = getCollectionActor();
    let collections = ['btcFlower', 'ethFlower', 'icpFlower']
    let nonce = 10_000 * collections.indexOf(collection) + tokenIndex;
    let stakingAccount = await $store.gardenActor.getStakingAccount(nonce);

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

    let stakeRes = await $store.gardenActor.stake(nonce);
    if ('err' in stakeRes) {
      error = stakeRes.err;
      return;
    }

    await refreshGarden();

    loading = false;
    openModal = false;
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <Button on:click={toggleModal}>Stake</Button>
</FlowerPreview>

{#if openModal}
  <Modal title="Stake Flower" {toggleModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      {#if error}
        <div class="text-red-700 text-xl flex flex-col grow">
          <div>Error</div>
          <div>{error}</div>
        </div>
      {:else if success}
        <div class="text-xl flex flex-col gap-4">
        </div>
      {:else}
        <div class="text-xl flex flex-col gap-4">
          <div>You are about to stake your flower.</div>
          <div>Staked flower will give you X SEED tokens every day.</div>
          <div>If you decide to unstake the flower you have to wait 30 day before you can withdraw the flower.</div>
        </div>
        <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" disabled={loading} on:click={stake}>
          {#if loading}
            <Loader {loading}></Loader>
          {:else}
            Stake!
          {/if}
        </Button>
      {/if}
    </div>
  </Modal>
{/if}