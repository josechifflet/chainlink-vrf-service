// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { Vm } from "forge-std/Vm.sol";

import { IVRFHandler } from "src/IVRFHandler.sol";
import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/*─────────────────────────────────────────────────────────────────────────────────────
│ Attack helpers
└─────────────────────────────────────────────────────────────────────────────────────*/

/// @dev Receiver that always reverts on callback — simulates griefing / DoS
contract GriefingReceiver {
  IVRFHandler public handler;

  constructor(address _handler) {
    handler = IVRFHandler(_handler);
  }

  function requestWithCallback() external returns (uint256) {
    return handler.requestRandomWords(1, this.boom.selector);
  }

  // Callback that always reverts — attacker griefs fulfillment
  function boom(uint256, uint256[] calldata) external pure {
    revert("griefed");
  }
}

/// @dev Receiver that writes to storage in a loop — DoS via gas exhaustion
contract GasGuzzlerReceiver {
  IVRFHandler public handler;
  uint256 public junk;

  constructor(address _handler) {
    handler = IVRFHandler(_handler);
  }

  function requestWithCallback() external returns (uint256) {
    return handler.requestRandomWords(1, this.guzzle.selector);
  }

  // Write to storage repeatedly until gas runs out
  function guzzle(uint256, uint256[] calldata) external {
    for (uint256 i; i < 1_000_000; i++) {
      junk = i;
    }
  }
}

/*─────────────────────────────────────────────────────────────────────────────────────
│ Red-team exploit tests — verify mitigations hold
└─────────────────────────────────────────────────────────────────────────────────────*/

contract VRFHandlerTest_RedTeam is VRFHandlerTest {
  /*───────────────────── ATTACK 1: Callback revert no longer griefs fulfillment ───*/
  // Severity: HIGH (was) | Boundary: integration
  // Fix: low-level call absorbs revert, emits CallbackFailed instead

  function test_mitigated_callbackRevertDoesNotBlockFulfillment() public {
    // Deploy griefing receiver and whitelist it
    GriefingReceiver griefer = new GriefingReceiver(address(vrfHandler));
    vm.prank(deployer);
    vrfHandler.addAllowedRequester(address(griefer));

    // Griefer makes a request with a reverting callback
    uint256 requestId = griefer.requestWithCallback();
    uint256[] memory randomWords = _generateRandomWords(1);

    // Fulfill — must NOT revert despite bad callback
    vm.prank(address(coordinator));
    vm.recordLogs();
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Fulfillment succeeded — request is marked done
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
    assertEq(vrfHandler.activeRequests(), 0);

    // CallbackFailed event was emitted
    Vm.Log[] memory logs = vm.getRecordedLogs();
    bool foundCallbackFailed = false;
    for (uint256 i; i < logs.length; i++) {
      if (logs[i].topics[0] == keccak256("CallbackFailed(uint256,address,bytes)")) {
        foundCallbackFailed = true;
        break;
      }
    }
    assertTrue(foundCallbackFailed, "CallbackFailed event not emitted");
  }

  /*───────────────────── ATTACK 2: Gas exhaustion no longer blocks fulfillment ────*/
  // Severity: HIGH (was) | Boundary: integration
  // Fix: same as above — low-level call absorbs OOG from callback

  function test_mitigated_gasExhaustionDoesNotBlockFulfillment() public {
    GasGuzzlerReceiver guzzler = new GasGuzzlerReceiver(address(vrfHandler));
    vm.prank(deployer);
    vrfHandler.addAllowedRequester(address(guzzler));

    uint256 requestId = guzzler.requestWithCallback();
    uint256[] memory randomWords = _generateRandomWords(1);

    // Fulfill — must NOT revert despite gas-guzzling callback
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Fulfillment succeeded
    assertTrue(vrfHandler.vrfFulfilledRequests(requestId));
    assertEq(vrfHandler.activeRequests(), 0);
  }

  /*───────────────────── ATTACK 3: setVrfConfig rejects zero values ──────────────*/
  // Severity: MEDIUM (was) | Boundary: unit
  // Fix: added validation matching constructor guards

  function test_mitigated_setVrfConfigRejectsZeroKeyHash() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.setVrfConfig(bytes32(0), 1, 3, 500_000, false);
    vm.stopPrank();
  }

  function test_mitigated_setVrfConfigRejectsZeroSubscriptionId() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.setVrfConfig(bytes32(uint256(1)), 0, 3, 500_000, false);
    vm.stopPrank();
  }

  function test_mitigated_setVrfConfigRejectsZeroCallbackGasLimit() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.setVrfConfig(bytes32(uint256(1)), 1, 3, 0, false);
    vm.stopPrank();
  }

  function test_mitigated_setVrfConfigAcceptsValidValues() public {
    vm.startPrank(deployer);
    vrfHandler.setVrfConfig(bytes32(uint256(2)), 100, 10, 1_000_000, true);
    vm.stopPrank();

    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();
    assertEq(config.keyHash, bytes32(uint256(2)));
    assertEq(config.subscriptionId, 100);
    assertEq(config.callbackGasLimit, 1_000_000);
  }

  /*───────────────────── ATTACK 5: Commitment not cleaned — design acknowledged ──*/
  // Severity: LOW | Boundary: unit
  // Verdict: Design decision — commitment data intentionally persists for
  //          post-fulfillment verification. Not a fix target.

  function test_acknowledged_commitmentPersistsAfterFulfillment() public {
    bytes32 manifestHash = keccak256("manifest");

    vm.prank(address(receiver));
    uint256 requestId = vrfHandler.requestRandomWordsWithCommitment(1, manifestHash, 100);

    uint256[] memory randomWords = _generateRandomWords(1);
    vm.prank(address(coordinator));
    vrfHandler.rawFulfillRandomWords(requestId, randomWords);

    // Commitment data intentionally persists for verification
    VRFHandler.Commitment memory c = vrfHandler.getCommitment(requestId);
    assertTrue(c.manifestHash != bytes32(0));
  }
}
