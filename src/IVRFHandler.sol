// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IVRFHandler {
  function requestRandomWords(uint32 randomWordsAmount) external returns (uint256 requestId);
}
