<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import FlowerPreview from './FlowerPreview.svelte';
  import StakeModal from './StakeModal.svelte';
  import { Collection } from '../types';

  export let collection: Collection;
  export let tokenIndex: number;

  let stakeModal: StakeModal;

  function toggleModal() {
    stakeModal.toggleModal();
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <Button style="!w-40" on:click={toggleModal}>Plant</Button>
</FlowerPreview>

<StakeModal {collection} {tokenIndex} bind:this={stakeModal}></StakeModal>