<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import FlowerPreview from './FlowerPreview.svelte';
  import StakeModal from './StakeModal.svelte';

  export let collection: 'btcFlower' | 'ethFlower' | 'icpFlower';
  export let tokenIndex: number;

  let stakeModal: StakeModal;

  function toggleModal() {
    stakeModal.toggleModal();
  }
</script>

<FlowerPreview {collection} {tokenIndex}>
  <Button on:click={toggleModal}>Stake</Button>
</FlowerPreview>

<StakeModal {collection} {tokenIndex} bind:this={stakeModal}></StakeModal>