// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "src/IVRFHandler.sol";

/// @title VRFHandler Mock
/// @notice A mock implementation of the VRFHandler interface for testing
contract VRFHandlerMock is IVRFHandler {
  uint256 private _requestId = 0;
  mapping(uint256 => address) public requestIdToRequester;

  function requestRandomWords(uint32 randomWordsAmount) external override returns (uint256 requestId) {
    _requestId++;
    requestIdToRequester[_requestId] = msg.sender;
    return _requestId;
  }

  function requestRandomWords(uint32 randomWordsAmount, bytes4 selector) external override returns (uint256 requestId) {
    _requestId++;
    requestIdToRequester[_requestId] = msg.sender;
    return _requestId;
  }

  function mock_fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    address requester = requestIdToRequester[requestId];
    require(requester != address(0), "VRFHandlerMock: Unknown request ID");

    (bool success,) = requester.call(
      abi.encodeWithSelector(bytes4(keccak256("fulfillRandomWords(uint256,uint256[])")), requestId, randomWords)
    );
    require(success, "VRFHandlerMock: Callback failed");
  }
}
