# Garden

## Preparation for development
```
git submodule update --init
npm install
npm i ic-mops -g
```

Create a `set-deploy-env.zsh` file in the root directory according to the following example and replace the `WALLET_ADDRESS` with your Plug wallet address

```sh
export WALLET_ADDRESS="8b61ff722d7e6321eb99bb607ab0cf323b3c64b43d6a13c245c8a4e197f7b38b"
```

## Development

```bash
npm start
```

## Testing

```bash
npm test
```

### Deploy to production
```
npm run deploy-ic
```

### Halvings
- 1748131200000 - May 25 2025, 00:00 UTC
- 1779667200000 - May 25 2026, 00:00 UTC
- 1811203200000 - May 25 2027, 00:00 UTC
- 1842825600000 - May 25 2028, 00:00 UTC