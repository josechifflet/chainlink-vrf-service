// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Mock VRF Coordinator V2 Plus
/// @notice A simplified mock of Chainlink's VRF Coordinator for testing purposes
contract MockVRFCoordinatorV2Plus {
  uint256 private _nextRequestId = 1;
  mapping(uint256 => address) public s_consumers;

  /// @notice Mock implementation of requestRandomWords
  /// @return requestId The unique ID for this request
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata /* request */ )
    external
    returns (uint256 requestId)
  {
    requestId = _nextRequestId++;
    s_consumers[requestId] = msg.sender;
    return requestId;
  }

  /// @notice For backwards compatibility with tests expecting a bytes parameter
  function requestRandomWords(bytes calldata /* request */ ) external returns (uint256 requestId) {
    requestId = _nextRequestId++;
    s_consumers[requestId] = msg.sender;
    return requestId;
  }

  /// @notice Helper to get the stored consumer for a request ID
  function getConsumer(uint256 requestId) external view returns (address) {
    return s_consumers[requestId];
  }
}
