// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { Vm } from "forge-std/Vm.sol";
import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/// @title Tests for VRFHandler commitment functionality
contract VRFHandlerTest_Commitment is VRFHandlerTest {
  bytes32 constant MANIFEST_HASH = keccak256("test-manifest-v1");
  uint256 constant RANGE_SIZE = 1000;

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ requestRandomWordsWithCommitment tests
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Test successful commitment request
  function test_requestRandomWordsWithCommitment_success() public {
    vm.startPrank(address(receiver));

    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(3, MANIFEST_HASH, RANGE_SIZE);

    // Verify request was created
    assertGt(requestId, 0);
    assertEq(vrfHandler.activeRequests(), 1);

    // Verify commitment was stored
    VRFHandler.Commitment memory commitment = vrfHandler.getCommitment(requestId);
    assertEq(commitment.manifestHash, MANIFEST_HASH);
    assertEq(commitment.rangeSize, RANGE_SIZE);
    assertEq(commitment.count, 3);
    assertEq(commitment.requester, address(receiver));
    assertEq(commitment.committedAt, block.timestamp);

    vm.stopPrank();
  }

  /// @notice Test commitment request emits correct events
  function test_requestRandomWordsWithCommitment_emitsEvents() public {
    vm.startPrank(address(receiver));

    // Expect RandomWordsRequested event
    vm.expectEmit(true, true, false, true);
    emit VRFHandler.RandomWordsRequested(1, address(receiver), 5);

    // Expect CommitmentStored event
    vm.expectEmit(true, true, false, true);
    emit VRFHandler.CommitmentStored(1, MANIFEST_HASH, RANGE_SIZE, 5);

    vrfHandler.requestRandomWordsWithCommitment(5, MANIFEST_HASH, RANGE_SIZE);

    vm.stopPrank();
  }

  /// @notice Test commitment request reverts for unauthorized caller
  function test_requestRandomWordsWithCommitment_revert_unauthorized() public {
    vm.startPrank(randomUser);
    vm.expectRevert(VRFHandler.Unauthorized.selector);
    vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, RANGE_SIZE);
    vm.stopPrank();
  }

  /// @notice Test commitment request reverts for zero random words
  function test_requestRandomWordsWithCommitment_revert_zeroRandomWords() public {
    vm.startPrank(address(receiver));
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.requestRandomWordsWithCommitment(0, MANIFEST_HASH, RANGE_SIZE);
    vm.stopPrank();
  }

  /// @notice Test commitment request reverts for zero manifest hash
  function test_requestRandomWordsWithCommitment_revert_zeroManifestHash() public {
    vm.startPrank(address(receiver));
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.requestRandomWordsWithCommitment(1, bytes32(0), RANGE_SIZE);
    vm.stopPrank();
  }

  /// @notice Test commitment request reverts for zero range size
  function test_requestRandomWordsWithCommitment_revert_zeroRangeSize() public {
    vm.startPrank(address(receiver));
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, 0);
    vm.stopPrank();
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ fulfillRandomWords with commitment tests
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Test fulfillment with commitment emits correct event
  function test_fulfillRandomWordsWithCommitment_emitsEvent() public {
    // Create commitment request
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(3, MANIFEST_HASH, RANGE_SIZE);

    // Generate random words
    uint256[] memory randomWords = _generateRandomWords(3);

    // Compute expected results
    uint256[] memory expectedResults = new uint256[](3);
    for (uint256 i; i < 3; i++) {
      expectedResults[i] = (randomWords[i] % RANGE_SIZE) + 1;
    }

    // Expect RandomWordsFulfilledWithCommitment event
    vm.expectEmit(true, true, false, true);
    emit VRFHandler.RandomWordsFulfilledWithCommitment(requestId, MANIFEST_HASH, randomWords, expectedResults);

    // Fulfill the request
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);
  }

  /// @notice Test fulfillment computes results correctly
  function test_fulfillRandomWordsWithCommitment_computesResultsCorrectly() public {
    uint256 rangeSize = 100;

    // Create commitment request
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(5, MANIFEST_HASH, rangeSize);

    // Use specific random words for predictable results
    uint256[] memory randomWords = new uint256[](5);
    randomWords[0] = 0; // (0 % 100) + 1 = 1
    randomWords[1] = 99; // (99 % 100) + 1 = 100
    randomWords[2] = 100; // (100 % 100) + 1 = 1
    randomWords[3] = 150; // (150 % 100) + 1 = 51
    randomWords[4] = type(uint256).max; // (max % 100) + 1

    // Expected results
    uint256[] memory expectedResults = new uint256[](5);
    expectedResults[0] = 1;
    expectedResults[1] = 100;
    expectedResults[2] = 1;
    expectedResults[3] = 51;
    expectedResults[4] = (type(uint256).max % rangeSize) + 1;

    // Capture event
    vm.recordLogs();
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);

    // Verify event was emitted with correct results
    Vm.Log[] memory logs = vm.getRecordedLogs();
    bool foundCommitmentEvent = false;
    for (uint256 i; i < logs.length; i++) {
      if (logs[i].topics[0] == keccak256("RandomWordsFulfilledWithCommitment(uint256,bytes32,uint256[],uint256[])")) {
        foundCommitmentEvent = true;
        // Decode the event data
        (uint256[] memory emittedRandomWords, uint256[] memory emittedResults) =
          abi.decode(logs[i].data, (uint256[], uint256[]));

        assertEq(emittedResults.length, 5);
        for (uint256 j; j < 5; j++) {
          assertEq(emittedResults[j], expectedResults[j]);
        }
        break;
      }
    }
    assertTrue(foundCommitmentEvent, "CommitmentFulfilled event not found");
  }

  /// @notice Test results are always within valid range (1 to rangeSize)
  function testFuzz_fulfillRandomWordsWithCommitment_resultsInRange(uint256 randomWord, uint256 rangeSize) public {
    // Bound rangeSize to reasonable values (1 to 10 million)
    rangeSize = bound(rangeSize, 1, 10_000_000);

    // Create commitment request
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, rangeSize);

    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = randomWord;

    // Capture event
    vm.recordLogs();
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);

    // Find and verify the result
    Vm.Log[] memory logs = vm.getRecordedLogs();
    for (uint256 i; i < logs.length; i++) {
      if (logs[i].topics[0] == keccak256("RandomWordsFulfilledWithCommitment(uint256,bytes32,uint256[],uint256[])")) {
        (, uint256[] memory results) = abi.decode(logs[i].data, (uint256[], uint256[]));
        // Result must be >= 1 and <= rangeSize
        assertGe(results[0], 1);
        assertLe(results[0], rangeSize);
        break;
      }
    }
  }

  /// @notice Test fulfillment with commitment still emits regular RandomWordsFulfilled
  function test_fulfillRandomWordsWithCommitment_alsoEmitsRegularEvent() public {
    // Create commitment request
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(2, MANIFEST_HASH, RANGE_SIZE);

    uint256[] memory randomWords = _generateRandomWords(2);

    // Expect regular RandomWordsFulfilled event
    vm.expectEmit(true, true, false, true);
    emit VRFHandler.RandomWordsFulfilled(requestId, address(receiver), randomWords);

    _fulfillRandomWordsAsCoordinator(requestId, randomWords);
  }

  /// @notice Test commitment data persists after fulfillment (for verification)
  function test_fulfillRandomWordsWithCommitment_commitmentPersistsAfterFulfill() public {
    // Create commitment request
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, RANGE_SIZE);

    // Store commitment timestamp
    VRFHandler.Commitment memory commitmentBefore = vrfHandler.getCommitment(requestId);

    // Fulfill the request
    uint256[] memory randomWords = _generateRandomWords(1);
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);

    // Commitment data should still be readable for verification
    VRFHandler.Commitment memory commitmentAfter = vrfHandler.getCommitment(requestId);
    assertEq(commitmentAfter.manifestHash, MANIFEST_HASH);
    assertEq(commitmentAfter.rangeSize, RANGE_SIZE);
    assertEq(commitmentAfter.count, 1);
    assertEq(commitmentAfter.committedAt, commitmentBefore.committedAt);
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ getCommitment tests
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Test getCommitment returns empty for non-existent request
  function test_getCommitment_returnsEmptyForNonExistent() public view {
    VRFHandler.Commitment memory commitment = vrfHandler.getCommitment(999);
    assertEq(commitment.manifestHash, bytes32(0));
    assertEq(commitment.rangeSize, 0);
    assertEq(commitment.count, 0);
    assertEq(commitment.committedAt, 0);
    assertEq(commitment.requester, address(0));
  }

  /// @notice Test getCommitment returns empty for regular request (no commitment)
  function test_getCommitment_returnsEmptyForRegularRequest() public {
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWords(1);

    VRFHandler.Commitment memory commitment = vrfHandler.getCommitment(requestId);
    assertEq(commitment.manifestHash, bytes32(0));
    assertEq(commitment.rangeSize, 0);
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Integration tests
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Test multiple commitment requests with different parameters
  function test_multipleCommitmentRequests() public {
    bytes32 hash1 = keccak256("manifest-1");
    bytes32 hash2 = keccak256("manifest-2");

    vm.startPrank(address(receiver));

    uint256 requestId1 = vrfHandler.requestRandomWordsWithCommitment(2, hash1, 100);
    uint256 requestId2 = vrfHandler.requestRandomWordsWithCommitment(5, hash2, 50_000);

    vm.stopPrank();

    // Verify both commitments stored correctly
    VRFHandler.Commitment memory c1 = vrfHandler.getCommitment(requestId1);
    VRFHandler.Commitment memory c2 = vrfHandler.getCommitment(requestId2);

    assertEq(c1.manifestHash, hash1);
    assertEq(c1.rangeSize, 100);
    assertEq(c1.count, 2);

    assertEq(c2.manifestHash, hash2);
    assertEq(c2.rangeSize, 50_000);
    assertEq(c2.count, 5);

    // Fulfill both
    uint256[] memory randomWords1 = _generateRandomWords(2);
    uint256[] memory randomWords2 = _generateRandomWords(5);

    _fulfillRandomWordsAsCoordinator(requestId1, randomWords1);
    _fulfillRandomWordsAsCoordinator(requestId2, randomWords2);

    // Both should be fulfilled
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId1));
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId2));
  }

  /// @notice Test commitment request mixed with regular requests
  function test_commitmentAndRegularRequestsMixed() public {
    vm.startPrank(address(receiver));

    // Regular request
    uint256 regularId = vrfHandler.requestRandomWords(1);

    // Commitment request
    uint256 commitmentId = vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, RANGE_SIZE);

    // Another regular request with callback
    uint256 callbackId = vrfHandler.requestRandomWords(1, bytes4(keccak256("customCallback(uint256,uint256[])")));

    vm.stopPrank();

    // Verify commitment only on commitment request
    assertEq(vrfHandler.getCommitment(regularId).manifestHash, bytes32(0));
    assertEq(vrfHandler.getCommitment(commitmentId).manifestHash, MANIFEST_HASH);
    assertEq(vrfHandler.getCommitment(callbackId).manifestHash, bytes32(0));

    // All should be active
    assertEq(vrfHandler.activeRequests(), 3);
  }

  /// @notice Fuzz test with various random words amounts and range sizes
  function testFuzz_requestRandomWordsWithCommitment(
    uint32 randomWordsAmount,
    bytes32 manifestHash,
    uint256 rangeSize
  )
    public
  {
    // Bound inputs to valid ranges
    randomWordsAmount = uint32(bound(randomWordsAmount, 1, 500));
    rangeSize = bound(rangeSize, 1, type(uint256).max);
    vm.assume(manifestHash != bytes32(0));

    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(randomWordsAmount, manifestHash, rangeSize);

    VRFHandler.Commitment memory commitment = vrfHandler.getCommitment(requestId);
    assertEq(commitment.manifestHash, manifestHash);
    assertEq(commitment.rangeSize, rangeSize);
    assertEq(commitment.count, randomWordsAmount);
    assertEq(commitment.requester, address(receiver));
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Edge case tests
  └─────────────────────────────────────────────────────────────────────────────────────*/

  /// @notice Test with rangeSize of 1 (all results should be 1)
  function test_fulfillWithCommitment_rangeSizeOne() public {
    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(3, MANIFEST_HASH, 1);

    uint256[] memory randomWords = new uint256[](3);
    randomWords[0] = 0;
    randomWords[1] = 12_345;
    randomWords[2] = type(uint256).max;

    vm.recordLogs();
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);

    // All results should be 1
    Vm.Log[] memory logs = vm.getRecordedLogs();
    for (uint256 i; i < logs.length; i++) {
      if (logs[i].topics[0] == keccak256("RandomWordsFulfilledWithCommitment(uint256,bytes32,uint256[],uint256[])")) {
        (, uint256[] memory results) = abi.decode(logs[i].data, (uint256[], uint256[]));
        assertEq(results[0], 1);
        assertEq(results[1], 1);
        assertEq(results[2], 1);
        break;
      }
    }
  }

  /// @notice Test with maximum rangeSize
  function test_fulfillWithCommitment_maxRangeSize() public {
    uint256 maxRange = type(uint256).max;

    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(1, MANIFEST_HASH, maxRange);

    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = 12_345;

    vm.recordLogs();
    _fulfillRandomWordsAsCoordinator(requestId, randomWords);

    Vm.Log[] memory logs = vm.getRecordedLogs();
    for (uint256 i; i < logs.length; i++) {
      if (logs[i].topics[0] == keccak256("RandomWordsFulfilledWithCommitment(uint256,bytes32,uint256[],uint256[])")) {
        (, uint256[] memory results) = abi.decode(logs[i].data, (uint256[], uint256[]));
        // Result should be randomWord + 1 (since randomWord < maxRange)
        assertEq(results[0], 12_346);
        break;
      }
    }
  }

  /*─────────────────────────────────────────────────────────────────────────────────────
  │ Helper functions
  └─────────────────────────────────────────────────────────────────────────────────────*/

  function _fulfillRandomWordsAsCoordinator(uint256 requestId, uint256[] memory randomWords) internal {
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);
  }
}
