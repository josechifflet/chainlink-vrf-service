// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { BaseScript } from "./base.s.sol";
import { ChainConfig } from "./utils/chains.sol";

/// @title VRFHandler Verification Script
/// @notice Helps verify a deployed VRFHandler contract on block explorers
contract VerifyVRFHandler is BaseScript {
  /// @notice Verifies the VRFHandler contract on Etherscan or similar block explorers
  /// @notice Requires that the contract is already deployed
  function run(uint256 chainId, address contractAddress) external view {
    // Verify the chain is supported
    if (!ChainConfig.isSupported(chainId)) revert("Unsupported chain ID. Set VRF_COORDINATOR and VRF_KEY_HASH in .env");

    // Load environment variables
    address coordinator = vm.envOr("VRF_COORDINATOR", ChainConfig.getCoordinator(chainId));
    bytes32 keyHash = vm.envOr("VRF_KEY_HASH", ChainConfig.getDefaultKeyHash(chainId));
    uint256 subscriptionId = vm.envUint("VRF_SUBSCRIPTION_ID");
    uint16 requestConfirmations = uint16(vm.envUint("VRF_REQUEST_CONFIRMATIONS"));
    uint32 callbackGasLimit = uint32(vm.envUint("VRF_CALLBACK_GAS_LIMIT"));
    bool nativePaymentEnabled = vm.envBool("VRF_NATIVE_PAYMENT_ENABLED");

    // Log verification parameters
    consoleLog("Verifying VRFHandler with the following parameters:");
    consoleLog("Network:", ChainConfig.getNetworkName(chainId));
    consoleLog("Contract Address:", contractAddress);
    consoleLog("Coordinator:", coordinator);
    consoleLog("Key Hash:", vm.toString(keyHash));
    consoleLog("Subscription ID:", subscriptionId);
    consoleLog("Request Confirmations:", requestConfirmations);
    consoleLog("Callback Gas Limit:", callbackGasLimit);
    consoleLog("Native Payment Enabled:", nativePaymentEnabled);

    // Build verification arguments array
    string memory args = vm.toString(
      abi.encode(coordinator, keyHash, subscriptionId, requestConfirmations, callbackGasLimit, nativePaymentEnabled)
    );

    // Use forge to verify the contract (command will be logged but not executed)
    string memory command = string.concat(
      "forge verify-contract ",
      vm.toString(contractAddress),
      " src/VRFHandler.sol:VRFHandler ",
      args,
      " --chain-id ",
      vm.toString(chainId)
    );

    consoleLog("Verification command:");
    consoleLog(command);

    // The actual verification command will need to be run manually with the appropriate API key
    consoleLog("Please run the above command with your Etherscan API key to verify the contract.");
  }
}
