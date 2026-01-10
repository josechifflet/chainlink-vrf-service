// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

/// @title Mock VRF Consumer Base V2 Plus
/// @notice A minimal mock of Chainlink's VRFConsumerBaseV2Plus contract
contract VRFConsumerBaseV2Plus {
  address public immutable s_vrfCoordinator;

  /// @notice Constructor sets the coordinator address
  constructor(address _vrfCoordinator) {
    s_vrfCoordinator = _vrfCoordinator;
  }

  /// @notice Function that verifies the caller is the VRF Coordinator
  /// @dev This function is called by the VRF service before calling fulfillRandomWords
  modifier onlyCoordinator() {
    require(msg.sender == s_vrfCoordinator, "Only callable by Coordinator");
    _;
  }

  /// @notice External function called by the VRF Coordinator to fulfill requests
  /// @param requestId The ID of the request to fulfill
  /// @param randomWords The random values generated from the VRF
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external onlyCoordinator {
    fulfillRandomWords(requestId, randomWords);
  }

  /// @notice Internal function that must be overridden by the inheriting contract
  /// @param requestId The ID of the request being fulfilled
  /// @param randomWords The random values to deliver to the consumer
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual { }
}
