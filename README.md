# Chainlink VRF Service

## Overview

The `VRFHandler` smart contract serves as an intermediary for Chainlink's VRF, providing a flexible and version-agnostic interface for requesting random numbers. By decoupling your main immutable contracts from direct Chainlink VRF dependencies, you ensure they remain functional even if Chainlink upgrades or changes their VRF services (e.g., from VRF 2.0 to VRF 2.5).

**Problem Addressed**: If your immutable smart contract is tightly coupled with a specific VRF version, any forced migration by Chainlink could render it unusable.

The `VRFHandler` mitigates this risk by allowing you to update or replace the handler without altering your main contract's logic.

## Features

- **Version-Agnostic Integration**: Protects your contracts from VRF version changes.
- **Decoupled Architecture**: Separates VRF logic from your main contracts.
- **Access Control**: Only authorized contracts can request random numbers.
- **Configurable Parameters**: Adjust VRF request settings as needed.
- **Native Payment Support**: Option to use native gas for VRF requests.

## Prerequisites

- **Solidity**: Version `0.8.26`
- **Chainlink Contracts**: Requires `@chainlink/contracts`

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/josechifflet/chainlink-vrf-service.git
   cd chainlink-vrf-service
   ```

2. **Install Dependencies**

   ```bash
   make install
   ```

Will install the dependencies and create a virtual environment.

## Usage

### Deployment

Deploy the `VRFHandler` contract with the following parameters:

```solidity
constructor(
  address _coordinator,
  bytes32 _keyHash,
  uint256 _subscriptionId,
  uint16 _requestConfirmations,
  uint32 _callbackGasLimit,
  bool _nativePaymentEnabled
)
```

- `_coordinator`: Chainlink VRF Coordinator address.
- `_keyHash`: Key hash for your VRF subscription.
- `_subscriptionId`: Your VRF subscription ID.
- `_requestConfirmations`: Number of confirmations required.
- `_callbackGasLimit`: Gas limit for the callback.
- `_nativePaymentEnabled`: Use native gas for requests if `true`.

### Integrate with Your Contract

1. **Implement the Receiver Interface**

   Your contract should implement the `IVRFHandlerReceiver` interface:

   ```solidity
   interface IVRFHandlerReceiver {
     function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external;
   }
   ```

2. **Request Random Numbers**

   As an authorized requester, call:

   ```solidity
   function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId);
   ```

   - `randomWordsAmount`: Number of random numbers needed.

3. **Handle the Callback**

   Implement the `fulfillRandomWords` function to receive the random numbers:

   ```solidity
   function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external override {
       // Your logic using _randomWords
   }
   ```

### Updating the VRF Handler

To adapt to VRF service changes, deploy a new `VRFHandler` with updated integrations and update the handler address in your main contract (e.g., via an `onlyOwner` function). This ensures continuity without modifying your main contract's immutable logic.

## Owner Functions

- **Manage Requesters**:

  ```solidity
  function addAllowedRequester(address _requester) external onlyOwner;
  function removeAllowedRequester(address _requester) external onlyOwner;
  ```

- **Configure VRF Settings**:

  ```solidity
  function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner;
  function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner;
  ```

## Events

- `AllowedRequesterAdded(address requester)`
- `AllowedRequesterRemoved(address requester)`
- `RequestConfirmationsSet(uint16 requestConfirmations)`
- `CallbackGasLimitSet(uint32 callbackGasLimit)`

## Security Considerations

- **Access Control**: Only add trusted contracts as allowed requesters.
- **Callback Security**: Ensure `fulfillRandomWords` handles inputs securely.
- **Upgradeable Handler Reference**: Implement a method to update the `VRFHandler` address in your main contract to adapt to future changes.

## Acknowledgments

This project was developed using the [foundry-template](https://github.com/PaulRBerg/foundry-template.git) by [Paul Razvan Berg](https://github.com/PaulRBerg).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
