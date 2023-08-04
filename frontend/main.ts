import App from './components/App.svelte';

const app = new App({
  // @ts-ignore
  target: document.getElementById('app')
});

export default app;