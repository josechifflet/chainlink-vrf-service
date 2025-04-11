// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/// @title VRF Coordinator V2.5 Mock
/// @notice A mock implementation of the Chainlink VRF Coordinator V2.5 for testing
contract VRFCoordinatorV2_5Mock {
  uint256 private _nextRequestId = 1;

  struct RandomWordsRequest {
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    bytes32 keyHash;
    uint64 subId;
    uint32 numWords;
    bytes extraArgs;
  }

  function requestRandomWords(RandomWordsRequest calldata request) external returns (uint256) {
    return _nextRequestId++;
  }
}
