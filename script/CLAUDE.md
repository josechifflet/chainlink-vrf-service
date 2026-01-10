# Deployment Scripts

## Files

```
script/
  base.s.sol      # Base script with broadcast modifier, console helpers
  deploy.s.sol    # VRFHandler deployment with config verification
  verify.s.sol    # Manual contract verification helper
  deploy.sh       # Shell wrapper for deployment
  utils/
    chains.sol    # Chain-specific VRF configs (coordinators, keyHashes)
```

## BaseScript

Provides:
- `broadcast(address)` modifier for transaction broadcasting
- `consoleLog` overloads for various types

## DeployVRFHandler

- Reads chain config from `ChainConfig` library
- Loads env vars: VRF_SUBSCRIPTION_ID, VRF_REQUEST_CONFIRMATIONS, etc.
- Deploys VRFHandler with verified configuration
- Validates deployed config matches expected

## ChainConfig

Supported networks with coordinator addresses and default keyHashes:
- Ethereum: mainnet (1), sepolia (11155111)
- Arbitrum: mainnet (42161), sepolia (421614)
- Base: mainnet (8453), sepolia (84532)
- Polygon: mainnet (137), amoy (80002)

## Deployment

```bash
# Via shell script
./script/deploy.sh $RPC_URL keystore/deploy.json 0xSender $API_KEY $CHAIN_ID

# Via forge
forge script script/deploy.s.sol:DeployVRFHandler --rpc-url $RPC --broadcast
```

## Env Vars

Required: VRF_SUBSCRIPTION_ID, VRF_REQUEST_CONFIRMATIONS, VRF_CALLBACK_GAS_LIMIT, VRF_NATIVE_PAYMENT_ENABLED
