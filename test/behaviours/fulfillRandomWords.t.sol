// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/// @title Tests for fulfillRandomWords function
contract VRFHandlerTest_FulfillRandomWords is VRFHandlerTest {
  /// @notice Test successful fulfillment of random words without callback
  function test_fulfillRandomWords_success() public {
    // First, request random words (no callback)
    uint32 numWords = 3;
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Generate random words for fulfillment
    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Expect event emission
    vm.expectEmit(true, true, false, true);
    emit RandomWordsFulfilled(requestId, address(receiver), randomWords);

    // Fulfill the request as the coordinator
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Verify state changes
    assertEq(vrfHandler.activeRequests(), 0);
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(0)); // Mapping cleared
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), bytes4(0)); // Selector cleared

    // Verify no callback was made (no selector = no callback)
    assertFalse(receiver.randomWordsFulfilled());
  }

  /// @notice Test fulfillment with custom callback
  function test_fulfillRandomWords_withCustomCallback_success() public {
    // Request with custom callback
    uint32 numWords = 3;
    uint256 requestId = receiver.requestRandomWordsWithCustomCallback();

    // Generate random words for fulfillment
    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Fulfill the request as the coordinator
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Verify the custom callback was called
    assertEq(receiver.lastRequestId(), requestId);

    // Check all random words were received correctly
    for (uint32 i = 0; i < numWords; i++) {
      assertEq(receiver.lastRandomWords(i), randomWords[i]);
    }
  }

  /// @notice Test revert when trying to fulfill a request twice
  function test_fulfillRandomWords_revert_alreadyFulfilled() public {
    // Request random words
    uint32 numWords = 1;
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Fulfill once
    uint256[] memory randomWords = _generateRandomWords(numWords);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Try to fulfill again - this should revert
    vm.prank(address(coordinator));
    vm.expectRevert();
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);
  }

  /// @notice Test revert when trying to fulfill a non-existent request
  function test_fulfillRandomWords_revert_nonExistentRequest() public {
    uint256 nonExistentRequestId = 999;
    uint256[] memory randomWords = _generateRandomWords(1);

    vm.prank(address(coordinator));
    vm.expectRevert();
    vrfHandler.rawFulfillRandomWords(nonExistentRequestId, randomWords);
  }

  /// @notice Test handling receiver reversion when using callback
  function test_fulfillRandomWords_receiverReverts() public {
    uint32 numWords = 1;

    // Make a request with a callback (custom callback)
    uint256 requestId = receiver.requestRandomWordsWithCustomCallback();

    // Set the receiver to revert when called
    receiver.setShouldRevert(true);

    // Prepare random words
    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Attempt to fulfill the request - should revert because the receiver reverts
    vm.prank(address(coordinator));
    vm.expectRevert();
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Reset the receiver to not revert
    receiver.setShouldRevert(false);
  }

  /// @notice Test only coordinator can call fulfillRandomWords
  function test_fulfillRandomWords_revert_onlyCoordinator() public {
    // Request random words
    uint32 numWords = 1;
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Generate random words
    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Try to fulfill from an unauthorized address
    vm.prank(randomUser);
    vm.expectRevert();
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);
  }

  /// @notice Test revert with specific error for already fulfilled
  function test_fulfillRandomWords_revert_alreadyFulfilled_specificError() public {
    uint32 numWords = 1;
    uint256 requestId = receiver.requestRandomWords(numWords);

    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Fulfill once
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Try again - should revert with InvalidVrfState
    vm.prank(address(coordinator));
    vm.expectRevert(VRFHandler.InvalidVrfState.selector);
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);
  }

  /// @notice Test revert with specific error for non-existent request
  function test_fulfillRandomWords_revert_nonExistent_specificError() public {
    uint256[] memory randomWords = _generateRandomWords(1);

    vm.prank(address(coordinator));
    vm.expectRevert(VRFHandler.Unauthorized.selector);
    vrfHandler.rawFulfillRandomWords(999, randomWords);
  }

  /// @notice Fuzz test for fulfillment with various random word counts
  function testFuzz_fulfillRandomWords_wordCount(uint32 numWords) public {
    vm.assume(numWords > 0 && numWords <= 100);

    uint256 requestId = receiver.requestRandomWords(numWords);
    uint256[] memory randomWords = _generateRandomWords(numWords);

    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
    assertEq(vrfHandler.activeRequests(), 0);
  }

  /// @notice Test fulfillment with fulfillRandomWords selector triggers callback
  function test_fulfillRandomWords_withDefaultSelector_triggersCallback() public {
    bytes4 fulfillSelector = bytes4(keccak256("fulfillRandomWords(uint256,uint256[])"));

    // Request with fulfillRandomWords selector
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(1, fulfillSelector);

    uint256[] memory randomWords = _generateRandomWords(1);

    // Fulfill
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Callback should have been triggered
    assertTrue(receiver.randomWordsFulfilled());
    assertEq(receiver.lastRequestId(), requestId);
  }

  /// @notice Test fulfilling multiple requests in sequence
  function test_fulfillRandomWords_multipleRequests() public {
    // Make multiple requests
    uint256 requestId1 = receiver.requestRandomWords(1);
    uint256 requestId2 = receiver.requestRandomWords(2);
    uint256 requestId3 = receiver.requestRandomWords(3);

    assertEq(vrfHandler.activeRequests(), 3);

    // Fulfill in different order
    uint256[] memory words2 = _generateRandomWords(2);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId2, words2);
    assertEq(vrfHandler.activeRequests(), 2);

    uint256[] memory words1 = _generateRandomWords(1);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId1, words1);
    assertEq(vrfHandler.activeRequests(), 1);

    uint256[] memory words3 = _generateRandomWords(3);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId3, words3);
    assertEq(vrfHandler.activeRequests(), 0);

    // All should be fulfilled
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId1));
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId2));
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId3));
  }

  /// @notice Test state is properly cleaned after fulfillment
  function test_fulfillRandomWords_stateCleanup() public {
    uint256 requestId = receiver.requestRandomWords(1);

    // Verify state before fulfillment
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));
    assertFalse(vrfHandler.vrfFulfilledRequests(requestId));

    uint256[] memory randomWords = _generateRandomWords(1);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Verify state after fulfillment
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(0));
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), bytes4(0));
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
  }

  /// @notice Integration test: full flow request -> fulfill with callback
  function test_integration_fullFlowWithCallback() public {
    // 1. Request random words with callback
    bytes4 customSelector = bytes4(keccak256("customCallback(uint256,uint256[])"));
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(5, customSelector);

    // 2. Verify request state
    assertEq(vrfHandler.activeRequests(), 1);
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(receiver));
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), customSelector);

    // 3. Fulfill
    uint256[] memory randomWords = _generateRandomWords(5);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // 4. Verify fulfillment state
    assertEq(vrfHandler.activeRequests(), 0);
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));

    // 5. Verify callback was executed
    assertEq(receiver.lastRequestId(), requestId);
    for (uint32 i = 0; i < 5; i++) {
      assertEq(receiver.lastRandomWords(i), randomWords[i]);
    }
  }

  /// @notice Integration test: full flow request -> fulfill without callback
  function test_integration_fullFlowWithoutCallback() public {
    // 1. Request random words without callback
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(3);

    // 2. Verify request state
    assertEq(vrfHandler.activeRequests(), 1);
    assertEq(vrfHandler.vrfRequestIdToSelector(requestId), bytes4(0));

    // 3. Fulfill
    uint256[] memory randomWords = _generateRandomWords(3);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // 4. Verify fulfillment state
    assertEq(vrfHandler.activeRequests(), 0);
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));

    // 5. Verify no callback was executed
    assertFalse(receiver.randomWordsFulfilled());
  }
}
