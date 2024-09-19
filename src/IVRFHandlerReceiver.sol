// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IVRFHandlerReceiver {
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}
