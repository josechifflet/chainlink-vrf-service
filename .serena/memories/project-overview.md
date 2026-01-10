# Chainlink VRF Service

## Purpose
Version-agnostic intermediary for Chainlink VRF random number generation. Decouples consumer contracts from direct VRF integration, enabling VRF version upgrades without modifying consumer logic.

## Architecture
- **VRFHandler** - Core contract inheriting `VRFConsumerBaseV2Plus`
- **IVRFHandler** - External API for requesting random words
- **IVRFHandlerReceiver** - Callback interface for consumers

## Request Flow
1. Consumer calls `requestRandomWords()` on VRFHandler
2. VRFHandler requests from Chainlink VRF Coordinator
3. Coordinator calls `fulfillRandomWords()` on VRFHandler
4. VRFHandler forwards to consumer via callback selector

## Key Features
- Allowed requesters whitelist (owner-managed)
- Custom callback selectors
- Native payment support
- Configurable gas limits and confirmations
- Active request tracking

## Supported Networks
- Ethereum (mainnet, sepolia)
- Arbitrum (mainnet, sepolia)
- Base (mainnet, sepolia)
- Polygon (mainnet, amoy)

## Tech Stack
- Solidity 0.8.29
- Foundry (forge, anvil)
- Chainlink VRF V2.5
