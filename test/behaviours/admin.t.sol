// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/// @title Tests for admin functions in VRFHandler
contract VRFHandlerTest_Admin is VRFHandlerTest {
  /// @notice Test adding allowed requester
  function test_addAllowedRequester_success() public {
    address newRequester = makeAddr("newRequester");

    vm.startPrank(deployer);

    // Expect event emission
    vm.expectEmit(true, false, false, true);
    emit AllowedRequesterAdded(newRequester);

    // Add requester
    vrfHandler.addAllowedRequester(newRequester);
    vm.stopPrank();

    // Verify the requester is now allowed
    assertTrue(vrfHandler.allowedRequesters(newRequester));
  }

  /// @notice Test removing allowed requester
  function test_removeAllowedRequester_success() public {
    // First, make sure our test receiver is allowed
    assertTrue(vrfHandler.allowedRequesters(address(receiver)));

    vm.startPrank(deployer);

    // Expect event emission
    vm.expectEmit(true, false, false, true);
    emit AllowedRequesterRemoved(address(receiver));

    // Remove requester
    vrfHandler.removeAllowedRequester(address(receiver));
    vm.stopPrank();

    // Verify the requester is now disallowed
    assertFalse(vrfHandler.allowedRequesters(address(receiver)));
  }

  /// @notice Test setting request confirmations
  function test_setRequestConfirmations_success() public {
    uint16 newConfirmations = 5;

    vm.startPrank(deployer);

    // Expect event emission
    vm.expectEmit(false, false, false, true);
    emit RequestConfirmationsSet(newConfirmations);

    // Set request confirmations
    vrfHandler.setRequestConfirmations(newConfirmations);
    vm.stopPrank();
  }

  /// @notice Test setting callback gas limit
  function test_setCallbackGasLimit_success() public {
    uint32 newGasLimit = 1_000_000;

    vm.startPrank(deployer);

    // Expect event emission
    vm.expectEmit(false, false, false, true);
    emit CallbackGasLimitSet(newGasLimit);

    // Set callback gas limit
    vrfHandler.setCallbackGasLimit(newGasLimit);
    vm.stopPrank();
  }

  /// @notice Test revert when non-owner tries to add allowed requester
  function test_addAllowedRequester_revert_notOwner() public {
    address newRequester = makeAddr("newRequester");

    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.addAllowedRequester(newRequester);
    vm.stopPrank();
  }

  /// @notice Test revert when non-owner tries to remove allowed requester
  function test_removeAllowedRequester_revert_notOwner() public {
    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.removeAllowedRequester(address(receiver));
    vm.stopPrank();
  }

  /// @notice Test revert when non-owner tries to set request confirmations
  function test_setRequestConfirmations_revert_notOwner() public {
    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.setRequestConfirmations(5);
    vm.stopPrank();
  }

  /// @notice Test revert when non-owner tries to set callback gas limit
  function test_setCallbackGasLimit_revert_notOwner() public {
    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.setCallbackGasLimit(1_000_000);
    vm.stopPrank();
  }

  /// @notice Test revert when adding zero address as requester
  function test_addAllowedRequester_revert_zeroAddress() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.addAllowedRequester(address(0));
    vm.stopPrank();
  }

  /// @notice Test revert when removing zero address as requester
  function test_removeAllowedRequester_revert_zeroAddress() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.removeAllowedRequester(address(0));
    vm.stopPrank();
  }

  /// @notice Test revert when setting zero callback gas limit
  function test_setCallbackGasLimit_revert_zeroGasLimit() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);
    vrfHandler.setCallbackGasLimit(0);
    vm.stopPrank();
  }
}
