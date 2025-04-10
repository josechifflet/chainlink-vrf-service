// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IVRFHandler {
  /// @notice Request random words with the default callback function (`fulfillRandomWords`)
  /// @param randomWordsAmount The number of random words to request
  /// @return requestId The request ID
  function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId);

  /// @notice Request random words with a custom selector as the callback function
  /// @param randomWordsAmount The number of random words to request
  /// @param selector The selector of the callback function
  /// @return requestId The request ID
  function requestRandomWords(uint32 randomWordsAmount, bytes4 selector) external returns (uint256 requestId);
}
