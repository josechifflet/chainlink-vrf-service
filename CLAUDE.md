# Chainlink VRF Service

Version-agnostic Chainlink VRF intermediary. Decouples consumer contracts from direct VRF integration.

## Commands

```bash
make build-dev       # Fast dev build
make test-fast       # Quick tests
make build-prod      # Production build
make deploy-anvil    # Local deployment
```

## Structure

```
src/           # Core contracts (VRFHandler, interfaces)
script/        # Deployment scripts
test/          # Tests and mocks
```

## Architecture

VRFHandler acts as proxy between consumers and Chainlink VRF Coordinator.

```
Consumer -> VRFHandler -> VRF Coordinator
                      <- fulfillRandomWords
Consumer <- callback
```

## Golden Rules

CRITICAL: All state changes before external calls (CEI pattern)
NEVER: Direct VRF coordinator calls from consumer contracts
ALWAYS: Whitelist consumers via `addAllowedRequester`
ALWAYS: Use custom errors, not revert strings

## Tech

- Solidity 0.8.29, Foundry, Chainlink VRF V2.5
- Networks: Ethereum, Arbitrum, Base, Polygon (mainnet + testnet)
