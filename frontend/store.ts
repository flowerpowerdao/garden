import { writable, get } from "svelte/store";
import { AuthStore, createAuthStore } from 'fpdao-ui/auth-store';
import {
  staging as ext,
  createActor as createExtActor,
  idlFactory as extIdlFactory,
} from "../declarations/ext";

let btcFlowerCanisterId = "pk6rk-6aaaa-aaaae-qaazq-cai";
let ethFlowerCanisterId = "dhiaa-ryaaa-aaaae-qabva-cai";
let icpFlowerCanisterId = "4ggk4-mqaaa-aaaae-qad6q-cai";

export const HOST = process.env.DFX_NETWORK !== "ic" ? "http://localhost:4943" : "https://icp0.io";

type State = {
  btcFlowerActor: typeof ext;
  ethFlowerActor: typeof ext;
  icpFlowerActor: typeof ext;
};

const defaultState: State = {
  btcFlowerActor: createExtActor(btcFlowerCanisterId, {
    agentOptions: { host: HOST },
  }),
  ethFlowerActor: createExtActor(ethFlowerCanisterId, {
    agentOptions: { host: HOST },
  }),
  icpFlowerActor: createExtActor(icpFlowerCanisterId, {
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
        let btcFlowerActor = await authStore.createActor<typeof ext>(btcFlowerCanisterId, extIdlFactory);
        let ethFlowerActor = await authStore.createActor<typeof ext>(ethFlowerCanisterId, extIdlFactory);
        let icpFlowerActor = await authStore.createActor<typeof ext>(icpFlowerCanisterId, extIdlFactory);
        update((prevState) => {
          return {
            ...prevState,
            btcFlowerActor,
            ethFlowerActor,
            icpFlowerActor,
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
    btcFlowerCanisterId,
    ethFlowerCanisterId,
    icpFlowerCanisterId,
  ],
  host: HOST,
});

export const store = createStore(authStore);