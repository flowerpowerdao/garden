<script lang="ts">
  import "fpdao-ui/styles/global.css";
  import { authStore, store } from '../store';

  let loading = false;

  $: if ($authStore.isAuthed) {
    load();
  };

  async function load() {
    if (loading) {
      return;
    }
    loading = true;
    let tokens = await $store.btcFlowerActor.tokens($authStore.accountId);
    console.log(tokens);
  }
</script>


<div
  class="py-10 lg:py-0 lg:flex lg:items-center lg:pt-40 lg:pb-8 lg:justify-between lg:mx-[11%] lg:flex-col"
>
  1111
</div>

<div
  class="flex flex-col justify-center gap-12 text-center max-w-6xl mb-40 dark:text-white p-10"
>
  Garden!
</div>