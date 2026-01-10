# Chainlink VRF Service

Version-agnostic intermediary for Chainlink VRF random number generation. Decouples consumer contracts from direct VRF integration, enabling seamless VRF version upgrades without modifying consumer logic.

## Installation

```bash
git clone https://github.com/josechifflet/chainlink-vrf-service.git
cd chainlink-vrf-service
make install
```

Prerequisites: [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Quick Start

### Build

```bash
make build-dev    # Fast development build
make build-prod   # Production build with optimization
```

### Test

```bash
make test-fast    # Quick tests
make test         # Full test suite with gas report
```

### Deploy

```bash
cp .env.example .env
# Edit .env with your configuration

./script/deploy.sh $RPC_URL keystore/deploy.json 0xYourAddress $API_KEY $CHAIN_ID
```

## Architecture

```
Consumer Contract ──> VRFHandler ──> Chainlink VRF Coordinator
                          │
                          └──> fulfillRandomWords callback
```

VRFHandler acts as a proxy, isolating your contracts from Chainlink VRF implementation details. When Chainlink upgrades VRF, only the handler needs updating.

### Contracts

| Contract | Description |
|----------|-------------|
| `VRFHandler` | Core intermediary, manages requests and callbacks |
| `IVRFHandler` | Interface for requesting random words |
| `IVRFHandlerReceiver` | Callback interface for consumers |

## Integration

### 1. Implement the receiver interface

```solidity
import { IVRFHandler } from "./IVRFHandler.sol";
import { IVRFHandlerReceiver } from "./IVRFHandlerReceiver.sol";

contract MyContract is IVRFHandlerReceiver {
    IVRFHandler public vrfHandler;

    constructor(address _vrfHandler) {
        vrfHandler = IVRFHandler(_vrfHandler);
    }

    function requestRandomness(uint32 numWords) external returns (uint256) {
        return vrfHandler.requestRandomWords(numWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        // Use random numbers
    }
}
```

### 2. Get whitelisted

The VRFHandler owner must add your contract:

```solidity
vrfHandler.addAllowedRequester(address(yourContract));
```

### 3. Custom callbacks (optional)

```solidity
function requestWithCustomCallback(uint32 numWords) external returns (uint256) {
    return vrfHandler.requestRandomWords(numWords, this.myCallback.selector);
}

function myCallback(uint256 requestId, uint256[] calldata randomWords) external {
    // Custom handling
}
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `VRF_SUBSCRIPTION_ID` | Chainlink VRF subscription ID |
| `VRF_REQUEST_CONFIRMATIONS` | Block confirmations before fulfillment |
| `VRF_CALLBACK_GAS_LIMIT` | Gas limit for callback execution |
| `VRF_NATIVE_PAYMENT_ENABLED` | Use native token for payment |

### Supported Networks

| Network | Chain ID | Coordinator |
|---------|----------|-------------|
| Ethereum Mainnet | 1 | `0xD7f86b4b8Cae7D942340FF628F82735b7a20893a` |
| Ethereum Sepolia | 11155111 | `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B` |
| Arbitrum Mainnet | 42161 | `0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e` |
| Arbitrum Sepolia | 421614 | `0x5CE8D5A2BC84beb22a398CCA51996F7930313D61` |
| Base Mainnet | 8453 | `0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634` |
| Base Sepolia | 84532 | `0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE` |
| Polygon Mainnet | 137 | `0xec0Ed46f36576541C75739E915ADbCb3DE24bD77` |
| Polygon Amoy | 80002 | `0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2` |

## Build Profiles

| Profile | Use Case | Command |
|---------|----------|---------|
| `dev` | Fast iteration | `make build-dev` |
| `deploy` | Production deployment | `make build-prod` |
| `test` | Testing | `make test-fast` |
| `gas` | Gas optimization analysis | `make build-gas` |
| `size` | Contract size optimization | `make build-size` |

Run `make help` for all available commands.

## API Reference

### VRFHandler

```solidity
// Request random words (default callback)
function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId);

// Request with custom callback selector
function requestRandomWords(uint32 randomWordsAmount, bytes4 selector) external returns (uint256 requestId);

// Admin functions (owner only)
function addAllowedRequester(address _requester) external;
function removeAllowedRequester(address _requester) external;
function setVrfConfig(bytes32 _keyHash, uint256 _subscriptionId, uint16 _requestConfirmations, uint32 _callbackGasLimit, bool _nativePaymentEnabled) external;
function setCallbackGasLimit(uint32 _callbackGasLimit) external;
function setRequestConfirmations(uint16 _requestConfirmations) external;
function setNativePaymentEnabled(bool _nativePaymentEnabled) external;
```

## License

MIT
