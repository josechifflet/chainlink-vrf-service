// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import { Script } from "forge-std/Script.sol";
// solhint-disable-next-line no-console
import { console } from "forge-std/console.sol";

/// @title BaseScript
/// @notice Foundation script that all deployment scripts inherit from
/// @dev Provides common functionality for all deployment scripts, including:
///      - Broadcasting transactions with proper logging
///      - Standardized error handling
///      - Common deployment patterns
///
/// This base contract ensures consistency across all deployment scripts
/// and reduces code duplication by centralizing common functionality.
/// It leverages Foundry's Script utilities for deployment automation.
contract BaseScript is Script {
  /// @notice Modifier to broadcast a transaction with proper logging and error handling
  /// @dev Wraps the function execution in startBroadcast and stopBroadcast calls
  ///      to ensure transactions are properly sent to the blockchain
  /// @param from The address of the sender, must be provided by the forge CLI
  ///             This address must be unlocked or have its private key available
  modifier broadcast(address from) {
    vm.startBroadcast(from);
    consoleLog("Broadcasting from:", from);

    _;

    vm.stopBroadcast();
  }

  /// @notice Log a string message with a prefix and bytes data
  function consoleLog(string memory message, bytes memory data) internal pure {
    // solhint-disable-next-line no-console
    console.log(message);
    // solhint-disable-next-line no-console
    console.logBytes(data);
  }

  /// @notice Log a string message with a prefix
  function consoleLog(string memory prefix, string memory message) internal pure {
    // solhint-disable-next-line no-console
    console.log(prefix, message);
  }

  /// @notice Log a number with a prefix
  function consoleLog(string memory prefix, uint256 value) internal pure {
    // solhint-disable-next-line no-console
    console.log(prefix, value);
  }

  /// @notice Log an address with a prefix
  function consoleLog(string memory prefix, address value) internal pure {
    // solhint-disable-next-line no-console
    console.log(prefix, value);
  }

  /// @notice Log a boolean with a prefix
  function consoleLog(string memory prefix, bool value) internal pure {
    // solhint-disable-next-line no-console
    console.log(prefix, value);
  }

  /// @notice Log just an address
  function consoleLog(address value) internal pure {
    // solhint-disable-next-line no-console
    console.log(value);
  }

  /// @notice Log just a string
  function consoleLog(string memory value) internal pure {
    // solhint-disable-next-line no-console
    console.log(value);
  }
}
