// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { VRFHandlerTest } from "test/VRFHandler.t.sol";
import { MockReceiver } from "test/mocks/MockReceiver.sol";

/// @title Tests for requestRandomWords functions
contract VRFHandlerTest_RequestRandomWords is VRFHandlerTest {
  /// @notice Test requestRandomWords with default callback
  function test_requestRandomWords_success() public {
    // Request random words through the mock receiver
    uint32 numWords = 1;

    // Call the function and store the result
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Verify request ID
    assertEq(requestId, 1);

    // Verify active requests count
    assertEq(vrfHandler.activeRequests(), 1);

    // Verify requester mapping is set correctly
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));

    // Verify selector mapping is set correctly
    bytes4 expectedSelector = bytes4(keccak256("fulfillRandomWords(uint256,uint256[])")); // IVRFHandlerReceiver.fulfillRandomWords.selector
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), expectedSelector);
  }

  /// @notice Test requestRandomWords with custom callback
  function test_requestRandomWords_withCustomCallback_success() public {
    uint32 numWords = 1;

    // Call the function and store the result
    uint256 requestId = receiver.requestRandomWordsWithCustomCallback();

    // Verify request ID
    assertEq(requestId, 1);

    // Verify active requests count
    assertEq(vrfHandler.activeRequests(), 1);

    // Verify requester mapping is set correctly
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));

    // Verify selector mapping is set correctly
    bytes4 expectedSelector = bytes4(keccak256("customCallback(uint256,uint256[])")); // receiver.customCallback.selector
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), expectedSelector);
  }

  /// @notice Test requesting multiple random words sequentially
  function test_requestRandomWords_multiple() public {
    // Request random words twice
    uint32 numWords = 1;

    // Call functions and reset VM state between tests to ensure deterministic behavior
    vm.deal(address(receiver), 1 ether); // Ensure receiver has enough ETH for gas

    vm.startPrank(address(receiver));
    uint256 requestId1 = vrfHandler.requestRandomWords(numWords);
    vm.stopPrank();

    // Verify first request
    assertEq(requestId1, 1);
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId1), address(receiver));

    vm.startPrank(address(receiver));
    uint256 requestId2 = vrfHandler.requestRandomWords(numWords);
    vm.stopPrank();

    // Verify second request
    assertEq(requestId2, 2);
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId2), address(receiver));

    // Verify total active requests count
    assertEq(vrfHandler.activeRequests(), 2);
  }

  /// @notice Test revert when unauthorized requester calls
  function test_requestRandomWords_revert_unauthorized() public {
    // Deploy a new receiver that's not authorized
    vm.startPrank(deployer);
    MockReceiver unauthorizedReceiver = new MockReceiver(address(vrfHandler));
    vm.stopPrank();

    // Try to request random words from unauthorized receiver
    vm.startPrank(address(unauthorizedReceiver));
    vm.expectRevert();
    vrfHandler.requestRandomWords(1);
    vm.stopPrank();
  }

  /// @notice Test revert when requesting zero random words
  function test_requestRandomWords_revert_zeroRandomWords() public {
    uint32 numWords = 0;

    vm.startPrank(address(receiver));
    vm.expectRevert();
    vrfHandler.requestRandomWords(numWords);
    vm.stopPrank();
  }

  /// @notice Test revert when using empty selector
  function test_requestRandomWords_revert_emptySelector() public {
    uint32 numWords = 1;
    bytes4 emptySelector = bytes4(0);

    vm.startPrank(address(receiver));
    vm.expectRevert();
    vrfHandler.requestRandomWords(numWords, emptySelector);
    vm.stopPrank();
  }

  /// @notice Test maximum request amount works correctly
  function test_requestRandomWords_maxAmount() public {
    // Request max allowed amount (if applicable to your contract)
    uint32 maxWords = 100; // Adjust based on your contract's max value

    vm.startPrank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(maxWords);
    vm.stopPrank();

    // Verify request ID and state
    assertEq(requestId, 1);
    assertEq(vrfHandler.activeRequests(), 1);
  }
}
