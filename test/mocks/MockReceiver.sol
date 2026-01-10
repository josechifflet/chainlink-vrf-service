// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { IVRFHandler } from "src/IVRFHandler.sol";
import { IVRFHandlerReceiver } from "src/IVRFHandlerReceiver.sol";

/// @title Mock VRF Receiver
/// @notice A mock contract that implements IVRFHandlerReceiver for testing
contract MockReceiver is IVRFHandlerReceiver {
  // Events
  event RandomWordsFulfilled(uint256 requestId, uint256[] randomWords);
  event CustomCallbackCalled(uint256 requestId, uint256[] randomWords);

  // State variables
  IVRFHandler public vrfHandler;
  bool public randomWordsFulfilled;
  uint256 public lastRequestId;
  uint256[] public lastRandomWords;
  uint32 public defaultNumWords = 1;
  bool public shouldRevert;

  /// @notice Sets the VRF handler address
  constructor(address _vrfHandler) {
    vrfHandler = IVRFHandler(_vrfHandler);
  }

  /// @notice Implements the IVRFHandlerReceiver interface
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external override {
    if (shouldRevert) revert("MockReceiver: Intentional revert");

    lastRequestId = requestId;
    delete lastRandomWords;
    for (uint256 i = 0; i < randomWords.length; i++) {
      lastRandomWords.push(randomWords[i]);
    }
    randomWordsFulfilled = true;

    emit RandomWordsFulfilled(requestId, randomWords);
  }

  /// @notice Custom callback function for testing
  function customCallback(uint256 requestId, uint256[] calldata randomWords) external {
    if (shouldRevert) revert("MockReceiver: Intentional revert");

    lastRequestId = requestId;
    delete lastRandomWords;
    for (uint256 i = 0; i < randomWords.length; i++) {
      lastRandomWords.push(randomWords[i]);
    }

    emit CustomCallbackCalled(requestId, randomWords);
  }

  /// @notice Request random words with default callback
  function requestRandomWords() external returns (uint256) {
    return vrfHandler.requestRandomWords(defaultNumWords);
  }

  /// @notice Request random words with specific amount
  function requestRandomWords(uint32 numWords) external returns (uint256) {
    uint256 requestId = vrfHandler.requestRandomWords(numWords);
    return requestId;
  }

  /// @notice Request random words with custom callback
  function requestRandomWordsWithCustomCallback() external returns (uint256) {
    bytes4 selector = this.customCallback.selector;
    return vrfHandler.requestRandomWords(defaultNumWords, selector);
  }

  /// @notice Request random words without callback
  function requestRandomWordsNoCallback() external returns (uint256) {
    return vrfHandler.requestRandomWords(defaultNumWords);
  }

  /// @notice Request random words without callback with specific amount
  function requestRandomWordsNoCallback(uint32 numWords) external returns (uint256) {
    return vrfHandler.requestRandomWords(numWords);
  }

  /// @notice Reset the mock state
  function reset() external {
    randomWordsFulfilled = false;
    lastRequestId = 0;
    delete lastRandomWords;
    shouldRevert = false;
  }

  /// @notice Set whether the callback should revert
  function setShouldRevert(bool _shouldRevert) external {
    shouldRevert = _shouldRevert;
  }

  /// @notice Set the default number of words to request
  function setDefaultNumWords(uint32 _defaultNumWords) external {
    defaultNumWords = _defaultNumWords;
  }

  /// @notice Get the last random words
  function getLastRandomWords() external view returns (uint256[] memory) {
    return lastRandomWords;
  }
}
