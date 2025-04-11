// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Test } from "forge-std/Test.sol";
import { IVRFHandler } from "src/IVRFHandler.sol";
import { IVRFHandlerReceiver } from "src/IVRFHandlerReceiver.sol";
import { VRFHandler } from "src/VRFHandler.sol";
import { MockReceiver } from "test/mocks/MockReceiver.sol";
import { MockVRFCoordinatorV2Plus } from "test/mocks/MockVRFCoordinatorV2Plus.sol";

/// @title Base test contract for VRFHandler
/// @notice Provides common setup and helper functions for all VRFHandler tests
contract VRFHandlerTest is Test {
  // Constants for VRF configuration
  bytes32 internal constant KEY_HASH = bytes32(uint256(1));
  uint256 internal constant SUBSCRIPTION_ID = 1;
  uint16 internal constant REQUEST_CONFIRMATIONS = 3;
  uint32 internal constant CALLBACK_GAS_LIMIT = 500_000;
  bool internal constant NATIVE_PAYMENT_ENABLED = false;

  // Test accounts
  address internal deployer;
  address internal requester;
  address internal randomUser;

  // Contract instances
  MockVRFCoordinatorV2Plus internal coordinator;
  VRFHandler internal vrfHandler;
  MockReceiver internal receiver;

  // Events from the VRFHandler contract
  event AllowedRequesterAdded(address indexed requester);
  event AllowedRequesterRemoved(address indexed requester);
  event RequestConfirmationsSet(uint16 requestConfirmations);
  event CallbackGasLimitSet(uint32 callbackGasLimit);
  event RandomWordsRequested(uint256 indexed requestId, address indexed requester, uint32 randomWordsAmount);
  event RandomWordsFulfilled(uint256 indexed requestId, address indexed requester, uint256[] randomWords);

  /// @notice Setup method executed before each test
  function setUp() public virtual {
    // Setup accounts
    deployer = makeAddr("deployer");
    requester = makeAddr("requester");
    randomUser = makeAddr("randomUser");

    // Setup contracts
    vm.startPrank(deployer);

    // Deploy mock coordinator
    coordinator = new MockVRFCoordinatorV2Plus();

    // Deploy VRFHandler
    vrfHandler = new VRFHandler(
      address(coordinator), KEY_HASH, SUBSCRIPTION_ID, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, NATIVE_PAYMENT_ENABLED
    );

    // Deploy mock receiver
    receiver = new MockReceiver(address(vrfHandler));

    // Add the receiver as an allowed requester
    vrfHandler.addAllowedRequester(address(receiver));

    vm.stopPrank();
  }

  /// @dev Helper function to generate random words for testing
  function _generateRandomWords(uint32 amount) internal pure returns (uint256[] memory) {
    uint256[] memory randomWords = new uint256[](amount);
    for (uint32 i = 0; i < amount; i++) {
      randomWords[i] = uint256(keccak256(abi.encode(i, "random seed")));
    }
    return randomWords;
  }

  /// @dev Helper function to simulate fulfillment of random words request
  function _fulfillRandomWordsCall(uint256 requestId, uint32 numWords) internal {
    uint256[] memory randomWords = _generateRandomWords(numWords);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);
  }
}
