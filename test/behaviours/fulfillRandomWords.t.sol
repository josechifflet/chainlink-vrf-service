// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/// @title Tests for fulfillRandomWords function
contract VRFHandlerTest_FulfillRandomWords is VRFHandlerTest {
  /// @notice Test successful fulfillment of random words
  function test_fulfillRandomWords_success() public {
    // First, request random words
    uint32 numWords = 3;
    uint256 requestId = receiver.requestRandomWords(numWords);

    // Generate random words for fulfillment
    uint256[] memory randomWords = _generateRandomWords(numWords);

    // Fulfill the request as the coordinator
    vm.prank(address(coordinator));

    // Fulfill and check state changes
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Verify state changes
    assertEq(vrfHandler.activeRequests(), 0);
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
    assertEq(vrfHandler.vrfRequestIdToRequester(requestId), address(0)); // Mapping cleared

    // Verify the receiver got the random words
    assertTrue(receiver.randomWordsFulfilled());
    assertEq(receiver.lastRequestId(), requestId);

    // Check all random words were received correctly
    for (uint32 i = 0; i < numWords; i++) {
      assertEq(receiver.lastRandomWords(i), randomWords[i]);
    }
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

  /// @notice Test handling receiver reversion
  function test_fulfillRandomWords_receiverReverts() public {
    uint32 numWords = 1;
    uint256 requestId;

    // Make a request using our standard setup
    vm.recordLogs();
    vm.prank(address(receiver));
    requestId = vrfHandler.requestRandomWords(numWords);

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
}
