// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IVRFHandlerReceiver {
  /// @notice Callback function for random words
  /// @param requestId The request ID
  /// @param randomWords The random words
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}
