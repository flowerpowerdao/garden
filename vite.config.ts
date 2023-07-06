/// <reference types="vitest" />
import {defineConfig} from 'vite';

export default defineConfig({
  test: {
    testTimeout: 1000 * 60,
    exclude: [
      '**/node_modules/**',
      '**/.{git,dfx,vessel,mops}/**',
    ],
  },
});