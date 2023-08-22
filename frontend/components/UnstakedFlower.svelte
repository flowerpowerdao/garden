<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';
  import Loader from 'fpdao-ui/components/Loader.svelte';
  import FlowerPreview from './FlowerPreview.svelte';
  import { authStore, store } from '../store';
  import { getCollectionCanisterId, toAccountId, tokenIdentifier } from '../utils';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;

  let loading = false;
  let openModal = false;

  function toggleModal() {
    openModal = !openModal;
    loading = false;
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
      throw res.err;
    }

    console.log('transfer', res);

    loading = false;
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <Button on:click={toggleModal}>Stake</Button>
</FlowerPreview>

{#if openModal}
  <Modal title="Stake Flower" {toggleModal}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
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
    </div>
  </Modal>
{/if}