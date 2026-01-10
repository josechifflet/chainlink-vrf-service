// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

interface IVRFHandler {
  /// @notice Request random words without a callback
  /// @dev Random words are emitted via RandomWordsFulfilled event only
  /// @param randomWordsAmount The number of random words to request
  /// @return requestId The request ID
  function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId);

  /// @notice Request random words with a callback
  /// @param randomWordsAmount The number of random words to request
  /// @param selector The selector of the callback function
  /// @return requestId The request ID
  function requestRandomWords(uint32 randomWordsAmount, bytes4 selector) external returns (uint256 requestId);
}
