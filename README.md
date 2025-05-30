# 🎲 Chainlink VRF Service

A version-agnostic intermediary smart contract for seamless integration of Chainlink's Verifiable Random Function (VRF) into your decentralized applications. This solution decouples your immutable contracts from direct VRF dependencies, ensuring they remain functional through VRF version upgrades.

## 📋 System Overview

The Chainlink VRF Service provides a robust and future-proof randomness solution through three primary components:

1. **🔄 VRF Handler** - Acts as the intermediary between your contracts and Chainlink VRF
2. **📝 Interface Layer** - Well-defined interfaces for consistent communication
3. **🔐 Access Control** - Security-focused permissions for randomness requests

This architecture ensures your contracts remain operational even when Chainlink upgrades their VRF service (e.g., from VRF 2.0 to VRF 2.5), as you can update only the handler contract.

## ✨ Features

- **🛡️ Version-Agnostic Design** - Shields your contracts from VRF implementation changes
- **🔄 Separation of Concerns** - Isolates VRF integration logic from your business logic
- **🔒 Access Control** - Only authorized contracts can request random numbers
- **⚙️ Configurable Parameters** - Adjust VRF settings based on your needs
- **💰 Native Payment Support** - Option to use native gas for VRF requests
- **🔌 Custom Callbacks** - Support for specialized handling of random numbers
- **📊 Request Tracking** - Monitor active and fulfilled randomness requests
- **⏱️ Gas Optimization** - Carefully structured for minimal gas consumption

## 🏗️ Architecture

The system follows a clean, modular design pattern:

- **📌 VRFHandler Contract** - Core contract implementing the Chainlink VRF consumer functionality
- **📝 IVRFHandler Interface** - Defines the external API for requesting random numbers
- **📝 IVRFHandlerReceiver Interface** - Standard for contracts consuming random numbers

This design provides:

- **🔄 Upgradeability** - Replace the handler without changing consumer contracts
- **🧩 Modularity** - Clear separation between randomness generation and consumption
- **🔗 Standardization** - Consistent interfaces for all components

## 📚 Technical Details

### 🔄 Request Flow

1. Consumer contracts call `requestRandomWords()` on VRFHandler
2. VRFHandler relays the request to Chainlink VRF
3. When fulfilled, VRFHandler receives random words from Chainlink
4. Random words are delivered to the original requester via callback

### 🔐 Security Considerations

- **🛡️ Access Control** - Only whitelisted contracts can request randomness
- **🧪 Input Validation** - All parameters strictly validated
- **⚠️ Error Handling** - Custom errors for clear failure modes
- **🔄 Check-Effects-Interactions Pattern** - Prevents reentrancy vulnerabilities
- **📜 Event Logging** - Comprehensive event emissions for off-chain monitoring

## 🚀 Getting Started

### 📋 Prerequisites

- **Solidity**: Version `0.8.29`
- **Chainlink Contracts**: `@chainlink/contracts`

### 📥 Installation

```bash
git clone https://github.com/josechifflet/chainlink-vrf-service.git
cd chainlink-vrf-service
make install
```

### ⚡ Build Optimization

This project includes optimized build profiles for different development scenarios:

#### 🚀 Quick Development Commands
```bash
# Fast development builds (5-20 seconds)
make build-dev        # Development build (via_ir=false, optimizer=false)
make build-fast       # Fastest build with sparse mode  
make test-fast        # Quick testing with optimized profile
make setup            # Fast project setup
```

#### 🎯 Specialized Builds
```bash
# Production deployment
make build-prod       # Full optimization (via_ir=true) for mainnet
make setup-prod       # Production setup with full optimization

# Performance focused
make build-gas        # Gas optimization (10k optimizer runs)
make build-size       # Size optimization (minimal runs)
make build-test       # Testing optimized (sparse mode, reduced fuzz runs)
```

#### 🔧 Development Utilities
```bash
# Performance analysis
make benchmark-build  # Compare build times across profiles
make cache-clean      # Clean build cache
make foundry-check    # Verify Foundry version compatibility

# Targeted builds
make build-contract CONTRACT=src/VRFHandler.sol
make test-specific CONTRACT=VRFHandlerTest
make test-function FUNCTION=testVRFRequest
```

#### 📊 Expected Performance
- **Development builds**: 5-20 seconds (vs 5-15 minutes previously)
- **Production builds**: 5-15 minutes with full optimization
- **Testing**: Significantly faster with sparse mode and reduced fuzz runs

Run `make help` to see all available build optimization commands and options.

### 🔧 Deployment

This project uses Foundry for deployment. The process is simplified using the provided deployment scripts.

#### 1. Configure Environment Variables

Create a `.env` file based on the `.env.example`:

```bash
cp .env.example .env
```

Update the `.env` file with:
- RPC URLs for your target networks
- Block explorer API keys for verification
- Any custom VRF configuration parameters

#### 2. Deploy the VRFHandler Contract

Use the `deploy.sh` script to deploy the contract to your chosen network:

```bash
# Format: ./script/deploy.sh <rpc-url> <keystore-account> <sender-address> <verification-api-key> <chain-id>

# Examples:
# Ethereum Sepolia
./script/deploy.sh $RPC_URL_SEPOLIA keystore/deploy.json 0xYourAddress $ETHERSCAN_API_KEY 11155111

# Polygon Mainnet
./script/deploy.sh $RPC_URL_POLYGON keystore/deploy.json 0xYourAddress $POLYGONSCAN_API_KEY 137

# Base Sepolia
./script/deploy.sh $RPC_URL_BASE_SEPOLIA keystore/deploy.json 0xYourAddress $BASESCAN_API_KEY 84532

# Arbitrum Mainnet
./script/deploy.sh $RPC_URL_ARBITRUM keystore/deploy.json 0xYourAddress $ARBISCAN_API_KEY 42161
```

The `deploy.sh` script will:
1. Load the appropriate configuration based on the specified chain ID
2. Deploy the VRFHandler contract with the default chain-specific parameters
3. Log the deployed contract address
4. Verify the contract on the appropriate block explorer

Alternatively, you can use forge directly:

```bash
forge script script/deploy.s.sol:DeployVRFHandler \
--rpc-url $RPC_URL \
--keystore ~/.foundry/keystores/your-keystore.json \
--sender 0xYourAddress \
--broadcast \
--verify \
--etherscan-api-key $API_KEY \
--sig "run(uint256 chainId, uint256 subscriptionId)" \
--args 1 1
```

#### 3. Contract Verification (Manual)

If automated verification fails during deployment, you can use the `verify.s.sol` script to manually verify the contract:

```bash
# Set the deployed contract address in your .env file
CONTRACT_ADDRESS=0x...

# Run the verification script
forge script script/verify.s.sol --rpc-url $RPC_URL
```

The script will output a verification command that you can run manually with your block explorer API key.

#### 4. Whitelist Consumer Contracts

Once deployed, whitelist your consumer contracts:

```solidity
handler.addAllowedRequester(address consumerContract);
```

#### 5. Network-Specific Configurations

The deployment script includes optimized default values for each supported network:

##### Ethereum
- **Mainnet (Chain ID: 1)**: Coordinator `0x271682DEB8C4E0901D1a1550aD2e64D568E69909`, KeyHash with 200 gwei premium
- **Sepolia (Chain ID: 11155111)**: Coordinator `0x9DDfACd722B7A7891Eb985e00C5F12A880CC8f4f`, KeyHash with 150 gwei premium

##### Arbitrum
- **Mainnet (Chain ID: 42161)**: Coordinator `0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e`, Default KeyHash with 30 gwei premium
- **Sepolia (Chain ID: 421614)**: Coordinator `0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634`, KeyHash with 30 gwei premium

##### Base
- **Mainnet (Chain ID: 8453)**: Coordinator `0xDf24F0718E2415Cc2B3A3fb12751E1A9428AcC97`, KeyHash with 50 gwei premium
- **Sepolia (Chain ID: 84532)**: Coordinator `0x2D159aE3BFF84D20a3dC6277126F570224fA9623`, KeyHash with 20 gwei premium

##### Polygon
- **Mainnet (Chain ID: 137)**: Coordinator `0xec0283dbb70BA32cEeb2e2d153eF0f2581e1CBD6`, KeyHash with 500 gwei premium
- **Mumbai (Chain ID: 80002)**: Coordinator `0x50d47e4142598e3411aa410e2c4de458665645B3`, KeyHash with 20 gwei premium

You can override these defaults by setting the appropriate values in your `.env` file.

#### Important Notes

- Before running the deployment on mainnet, make sure you've created a valid VRF subscription and have funded it adequately with LINK tokens
- You must specify the subscription ID when deploying (passed as the second argument to the script)
- For Arbitrum Mainnet, we use the 30 gwei key hash by default; you can override this with the `VRF_KEY_HASH` environment variable if you prefer a different premium
- Make sure your keystore file is properly set up in the `~/.foundry/keystores/` directory

### 🧩 Integration Steps

1. **Implement the IVRFHandlerReceiver interface in your contract**:

```solidity
contract MyContract is IVRFHandlerReceiver {
  IVRFHandler public vrfHandler;
  
  constructor(address _vrfHandler) {
    vrfHandler = IVRFHandler(_vrfHandler);
  }
  
  function requestRandomness(uint32 numWords) external {
    vrfHandler.requestRandomWords(numWords);
  }
  
  function fulfillRandomWords(
    uint256 requestId, 
    uint256[] calldata randomWords
  ) external override {
    // Use your random numbers here
  }
}
```

2. **For custom callbacks, use the selector variant**:

```solidity
function requestSpecialRandomness(uint32 numWords) external {
  vrfHandler.requestRandomWords(
    numWords,
    this.myCustomCallback.selector
  );
}

function myCustomCallback(
  uint256 requestId, 
  uint256[] calldata randomWords
) external {
  // Custom handling logic
}
```

## 🔄 Upgrading the Handler

When Chainlink updates their VRF implementation:

1. Deploy a new VRFHandler contract with updated Chainlink integrations
2. Update your consumer contracts to reference the new handler

Since your consumer contracts only interact through the interfaces, no logic changes are needed.

## 🧪 Testing

The repository includes comprehensive tests:

- **🔬 Unit Tests** - For individual contract functions
- **🔄 Integration Tests** - Verifying complete request and fulfillment flow
- **⚙️ Configuration Tests** - Validating proper parameter adjustments

Run tests with:

```bash
make test
```

## 📖 API Reference

### VRFHandler

- **requestRandomWords(uint32 randomWordsAmount)** - Request random words using default callback
- **requestRandomWords(uint32 randomWordsAmount, bytes4 selector)** - Request with custom callback
- **addAllowedRequester(address _requester)** - Add authorized requester (owner only)
- **removeAllowedRequester(address _requester)** - Remove authorization (owner only)
- **setRequestConfirmations(uint16 _requestConfirmations)** - Configure confirmations (owner only)
- **setCallbackGasLimit(uint32 _callbackGasLimit)** - Set callback gas limit (owner only)

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
