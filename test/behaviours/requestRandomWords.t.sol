// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";
import { MockReceiver } from "test/mocks/MockReceiver.sol";

/// @title Tests for requestRandomWords functions
contract VRFHandlerTest_RequestRandomWords is VRFHandlerTest {
  /// @notice Test requestRandomWords without callback
  function test_requestRandomWords_success() public {
    // Request random words through the mock receiver
    uint32 numWords = 1;

    // Expect event emission
    vm.expectEmit(true, true, false, true);
    emit RandomWordsRequested(1, address(receiver), numWords);

    // Call the function and store the result
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Verify request ID
    assertEq(requestId, 1);

    // Verify active requests count
    assertEq(vrfHandler.activeRequests(), 1);

    // Verify requester mapping is set correctly
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));

    // Verify selector mapping is bytes4(0) - no callback
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), bytes4(0));
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

  /// @notice Test requestRandomWords with custom callback emits event
  function test_requestRandomWords_withCallback_emitsEvent() public {
    uint32 numWords = 5;
    bytes4 selector = bytes4(keccak256("customCallback(uint256,uint256[])"));

    // Expect event emission
    vm.expectEmit(true, true, false, true);
    emit RandomWordsRequested(1, address(receiver), numWords);

    vm.startPrank(address(receiver));
    vrfHandler.requestRandomWords(numWords, selector);
    vm.stopPrank();
  }

  /// @notice Fuzz test for requestRandomWords amount
  function testFuzz_requestRandomWords_amount(uint32 numWords) public {
    vm.assume(numWords > 0);

    vm.startPrank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(numWords);
    vm.stopPrank();

    assertEq(requestId, 1);
    assertEq(vrfHandler.activeRequests(), 1);
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));
  }

  /// @notice Fuzz test for requestRandomWords with selector
  function testFuzz_requestRandomWords_selector(bytes4 selector) public {
    vm.assume(selector != bytes4(0));

    vm.startPrank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(1, selector);
    vm.stopPrank();

    assertEq(requestId, 1);
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), selector);
  }

  /// @notice Test revert with specific error selector for unauthorized
  function test_requestRandomWords_revert_unauthorized_specificError() public {
    vm.startPrank(randomUser);
    vm.expectRevert(VRFHandler.Unauthorized.selector);
    vrfHandler.requestRandomWords(1);
    vm.stopPrank();
  }

  /// @notice Test revert with specific error selector for zero words
  function test_requestRandomWords_revert_zeroWords_specificError() public {
    vm.startPrank(address(receiver));
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.requestRandomWords(0);
    vm.stopPrank();
  }

  /// @notice Test revert with specific error selector for empty selector
  function test_requestRandomWords_revert_emptySelector_specificError() public {
    vm.startPrank(address(receiver));
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.requestRandomWords(1, bytes4(0));
    vm.stopPrank();
  }

  /// @notice Test that request IDs are incremented correctly across multiple requests
  function test_requestRandomWords_incrementingIds() public {
    vm.startPrank(address(receiver));

    uint256 requestId1 = vrfHandler.requestRandomWords(1);
    uint256 requestId2 = vrfHandler.requestRandomWords(2);
    uint256 requestId3 = vrfHandler.requestRandomWords(3);

    vm.stopPrank();

    assertEq(requestId1, 1);
    assertEq(requestId2, 2);
    assertEq(requestId3, 3);
    assertEq(vrfHandler.activeRequests(), 3);
  }

  /// @notice Test requesting with fulfillRandomWords selector (default callback)
  function test_requestRandomWords_withFulfillRandomWordsSelector() public {
    bytes4 fulfillSelector = bytes4(keccak256("fulfillRandomWords(uint256,uint256[])"));

    vm.startPrank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(1, fulfillSelector);
    vm.stopPrank();

    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), fulfillSelector);
  }
}
