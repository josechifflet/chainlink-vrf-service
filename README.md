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

### 🔧 Deployment

1. **Deploy the VRFHandler contract**:

```solidity
VRFHandler handler = new VRFHandler(
  address coordinator,
  bytes32 keyHash,
  uint256 subscriptionId,
  uint16 requestConfirmations,
  uint32 callbackGasLimit,
  bool nativePaymentEnabled
);
```

2. **Whitelist your consumer contracts**:

```solidity
handler.addAllowedRequester(address consumerContract);
```

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
