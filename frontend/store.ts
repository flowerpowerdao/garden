import { writable, get } from "svelte/store";
import { AuthStore, createAuthStore } from 'fpdao-ui/auth-store';
import {
  main as garden,
  createActor as createGardenActor,
  idlFactory as gardenIdlFactory,
  canisterId as gardenCanisterId,
} from "../declarations/main";
import {
  staging as ext,
  createActor as createExtActor,
  idlFactory as extIdlFactory,
} from "../declarations/ext";
import { btcFlowerCanisterId, ethFlowerCanisterId, icpFlowerCanisterId, btcFlowerGen2CanisterId } from './canister-ids';

export const HOST = process.env.DFX_NETWORK !== "ic" ? "http://localhost:4943" : "https://ic0.app";

type State = {
  actorsAuthed: boolean;
  gardenActor: typeof garden;
  btcFlowerActor: typeof ext;
  ethFlowerActor: typeof ext;
  icpFlowerActor: typeof ext;
  btcFlowerGen2Actor: typeof ext;
};

const defaultState: State = {
  actorsAuthed: false,
  gardenActor: createGardenActor(gardenCanisterId, {
    agentOptions: { host: HOST },
  }),
  btcFlowerActor: createExtActor(btcFlowerCanisterId, {
    agentOptions: { host: HOST },
  }),
  ethFlowerActor: createExtActor(ethFlowerCanisterId, {
    agentOptions: { host: HOST },
  }),
  icpFlowerActor: createExtActor(icpFlowerCanisterId, {
    agentOptions: { host: HOST },
  }),
  btcFlowerGen2Actor: createExtActor(btcFlowerGen2CanisterId, {
    agentOptions: { host: HOST },
  }),
};

export const createStore = (authStore: AuthStore) => {
  const { subscribe, update } = writable<State>(defaultState);
  let curAuth = get(authStore).isAuthed;

  authStore.subscribe(async (state) => {
    if (curAuth !== state.isAuthed) {
      curAuth = state.isAuthed;

      if (curAuth == null) {
        update((prevState) => {
          return {...defaultState};
        });
      } else {
        let gardenActor = await authStore.createActor<typeof garden>(gardenCanisterId, gardenIdlFactory);
        let btcFlowerActor = await authStore.createActor<typeof ext>(btcFlowerCanisterId, extIdlFactory);
        let ethFlowerActor = await authStore.createActor<typeof ext>(ethFlowerCanisterId, extIdlFactory);
        let icpFlowerActor = await authStore.createActor<typeof ext>(icpFlowerCanisterId, extIdlFactory);
        let btcFlowerGen2Actor = await authStore.createActor<typeof ext>(btcFlowerGen2CanisterId, extIdlFactory);
        update((prevState) => {
          return {
            ...prevState,
            actorsAuthed: true,
            gardenActor,
            btcFlowerActor,
            ethFlowerActor,
            icpFlowerActor,
            btcFlowerGen2Actor,
          };
        });
      }
    }
  });

  subscribe((state) => {
    console.log("state", state);
  });

  return {
    subscribe,
    update,
  };
};

export const authStore = createAuthStore({
  whitelist: [
    'ryjl3-tyaaa-aaaaa-aaaba-cai',
    gardenCanisterId,
    btcFlowerCanisterId,
    ethFlowerCanisterId,
    icpFlowerCanisterId,
    btcFlowerGen2CanisterId,
  ],
  host: HOST,
});

export const store = createStore(authStore);