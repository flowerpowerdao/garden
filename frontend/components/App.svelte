<script lang="ts">
  import { onMount } from "svelte";
  import "fpdao-ui/styles/global.css";
  import Header from "fpdao-ui/components/Header.svelte";
  import Footer from "fpdao-ui/components/Footer.svelte";
  import { createAuthStore } from 'fpdao-ui/auth-store';

  let authStore = createAuthStore({
    whitelist: [], // canister ids...
    host: process.env.DFX_NETWORK !== "ic" ? "http://localhost:4943" : "https://icp0.io",
  });

  onMount(async () => {
    await authStore.checkConnections();
  });
</script>

<Header {authStore} />
Garden!
<Footer {authStore} />
