# VRFHandler Deployment Scripts

This directory contains scripts for deploying and verifying the VRFHandler contract.

## Project Structure

- `deploy.s.sol` - Main deployment script for the VRFHandler contract
- `verify.s.sol` - Script to help verify the deployed contract on block explorers
- `deploy.sh` - Shell script wrapper for easier deployment across different networks
- `utils/chains.sol` - Contains chain configuration data and utility functions
- `base.s.sol` - Base script with common functionality

## Prerequisites

1. Set up your environment variables in a `.env` file (see `.env.example` in the project root):

```sh
# Ethereum
RPC_URL_MAINNET=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
RPC_URL_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Arbitrum
RPC_URL_ARBITRUM=https://arb-mainnet.g.alchemy.com/v2/YOUR_API_KEY
RPC_URL_ARBITRUM_SEPOLIA=https://arb-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Base
RPC_URL_BASE=https://mainnet.base.org
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org

# Polygon
RPC_URL_POLYGON=https://polygon-mainnet.g.alchemy.com/v2/YOUR_API_KEY
RPC_URL_POLYGON_MUMBAI=https://polygon-mumbai.g.alchemy.com/v2/YOUR_API_KEY

# API Keys
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
ARBISCAN_API_KEY=YOUR_ARBISCAN_API_KEY
BASESCAN_API_KEY=YOUR_BASESCAN_API_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_API_KEY

# Optional VRF configuration - if not provided, defaults will be used based on chain
VRF_SUBSCRIPTION_ID=1
REQUEST_CONFIRMATIONS=3
CALLBACK_GAS_LIMIT=2500000
NATIVE_PAYMENT_ENABLED=true

# Deployment configurations
CAST_ACCOUNT=0xYourDeploymentAddress
SENDER_ADDRESS=0xYourDeploymentAddress
```

2. Ensure you have a Foundry keystore set up (`~/.foundry/keystores/`)

## Deployment

You can deploy the VRFHandler contract using the convenient shell script:

```sh
# Format: ./deploy.sh <RPC_URL> <CAST_ACCOUNT> <SENDER> <VERIFY_API_KEY> <CHAIN_ID> <SUBSCRIPTION_ID>

# Deploy to Ethereum Sepolia
./deploy.sh $RPC_URL_SEPOLIA cast_account 0xCastAccountSenderAddress $ETHERSCAN_API_KEY 11155111 $VRF_SUBSCRIPTION_ID

# Deploy to Polygon Mainnet
./deploy.sh $RPC_URL_POLYGON cast_account 0xCastAccountSenderAddress $POLYGONSCAN_API_KEY 137 $VRF_SUBSCRIPTION_ID

# Deploy to Base Sepolia
./deploy.sh $RPC_URL_BASE_SEPOLIA cast_account 0xCastAccountSenderAddress $BASESCAN_API_KEY 84532 $VRF_SUBSCRIPTION_ID

# Deploy to Arbitrum Mainnet
./deploy.sh $RPC_URL_ARBITRUM cast_account 0xCastAccountSenderAddress $ARBISCAN_API_KEY 42161 $VRF_SUBSCRIPTION_ID

# Deploy to Arbitrum Sepolia
./deploy.sh $RPC_URL_ARBITRUM_SEPOLIA cast_account 0xCastAccountSenderAddress $ARBISCAN_API_KEY 42161 $VRF_SUBSCRIPTION_ID
```

Alternatively, you can use forge directly:

```sh
forge script script/deploy.s.sol:DeployVRFHandler \
--rpc-url $RPC_URL \
--keystore ~/.foundry/keystores/cast_account \
--sender 0xCastAccountSenderAddress \
--broadcast \
--verify \
--etherscan-api-key $API_KEY \
--sig "run(uint256 chainId, uint256 subscriptionId)" \
--args 1 1
```

The script will:
1. Load the appropriate configuration based on the specified chain ID
2. Deploy the VRFHandler contract with the configuration
3. Log the deployed contract address
4. Attempt to verify the contract on the appropriate block explorer

## Verification

If the automated verification fails during deployment, you can use the `verify.s.sol` script to manually verify the contract:

```sh
# Run the verification script to get the verification command
forge script script/verify.s.sol:VerifyVRFHandler --rpc-url $RPC_URL
```

The script will output a verification command that you can run manually with your block explorer API key.

## Chain Configuration Library

The `utils/chains.sol` file contains the `ChainConfig` library that provides:

- Network-specific coordinator addresses and key hashes
- Helper functions to get the right configuration based on chain ID
- Network name mappings for readable output
- Chain support validation

If you need to add support for additional networks, update the `ChainConfig` library.

## Default Values

The deployment script includes default values for each supported network:

## Notes

- Before running the deployment on mainnet, make sure you've created a valid VRF subscription and have funded it adequately with LINK tokens
- You must specify the subscription ID when deploying (passed as the second argument to the script)
- For Arbitrum Mainnet, we use the 30 gwei key hash by default; you can override this with the `VRF_KEY_HASH` environment variable if you prefer a different premium
- Make sure your keystore file is properly set up in the `~/.foundry/keystores/` directory 