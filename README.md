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