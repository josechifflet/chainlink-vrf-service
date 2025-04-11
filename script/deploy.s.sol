// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { BaseScript } from "script/base.s.sol";
import { ChainConfig } from "script/utils/chains.sol";
import { VRFHandler } from "src/VRFHandler.sol";

/// @title VRFHandler Deployment Script
/// @notice Handles deployment of the VRFHandler contract with proper configuration
contract DeployVRFHandler is BaseScript {
  /// @notice Deploys the VRFHandler contract
  /// @return handler The deployed VRFHandler contract
  function run(uint256 chainId) external broadcast(msg.sender) returns (VRFHandler handler) {
    // Verify the chain is supported
    if (!ChainConfig.isSupported(chainId)) revert("Unsupported chain ID. Set VRF_COORDINATOR and VRF_KEY_HASH in .env");

    // Get configuration
    address coordinator = ChainConfig.getCoordinator(chainId);
    bytes32 keyHash = ChainConfig.getDefaultKeyHash(chainId);
    uint256 subscriptionId = vm.envUint("VRF_SUBSCRIPTION_ID");
    uint16 requestConfirmations = uint16(vm.envUint("VRF_REQUEST_CONFIRMATIONS"));
    uint32 callbackGasLimit = uint32(vm.envUint("VRF_CALLBACK_GAS_LIMIT"));
    bool nativePaymentEnabled = vm.envBool("VRF_NATIVE_PAYMENT_ENABLED");

    // Log deployment parameters
    consoleLog("Deploying VRFHandler with the following parameters:");
    consoleLog("Network:", ChainConfig.getNetworkName(chainId));
    consoleLog("Coordinator:", coordinator);
    consoleLog("Key Hash:", vm.toString(keyHash));
    consoleLog("Subscription ID:", subscriptionId);
    consoleLog("Request Confirmations:", requestConfirmations);
    consoleLog("Callback Gas Limit:", callbackGasLimit);
    consoleLog("Native Payment Enabled:", nativePaymentEnabled);

    // Deploy the VRFHandler contract
    handler =
      new VRFHandler(coordinator, keyHash, subscriptionId, requestConfirmations, callbackGasLimit, nativePaymentEnabled);

    consoleLog("VRFHandler deployed at:", address(handler));

    // Verify deployment by checking the VRF configuration
    VRFHandler.VRFConfig memory config = handler.getVrfConfig();

    consoleLog("\n--- Verifying VRF Configuration ---");
    bool configValid = true;

    if (config.subscriptionId != subscriptionId) {
      consoleLog("Subscription ID mismatch. Expected:", subscriptionId);
      consoleLog("Got:", config.subscriptionId);
      consoleLog("--------------------------------");
      configValid = false;
    }

    if (config.keyHash != keyHash) {
      consoleLog("Key Hash mismatch. Expected:", vm.toString(keyHash));
      consoleLog("Got:", vm.toString(config.keyHash));
      consoleLog("--------------------------------");
      configValid = false;
    }

    if (config.requestConfirmations != requestConfirmations) {
      consoleLog("Request Confirmations mismatch. Expected:", requestConfirmations);
      consoleLog("Got:", config.requestConfirmations);
      consoleLog("--------------------------------");
      configValid = false;
    }

    if (config.callbackGasLimit != callbackGasLimit) {
      consoleLog("Callback Gas Limit mismatch. Expected:", callbackGasLimit);
      consoleLog("Got:", config.callbackGasLimit);
      consoleLog("--------------------------------");
      configValid = false;
    }

    if (config.nativePaymentEnabled != nativePaymentEnabled) {
      consoleLog("Native Payment Enabled mismatch. Expected:", nativePaymentEnabled);
      consoleLog("Got:", config.nativePaymentEnabled);
      consoleLog("--------------------------------");
      configValid = false;
    }

    if (configValid) consoleLog("VRF Configuration successfully verified!");
    else consoleLog("VRF Configuration verification failed. Please check the contract state.");

    // Ensure owner is the sender
    require(handler.owner() == msg.sender, "Owner mismatch");

    return handler;
  }
}
