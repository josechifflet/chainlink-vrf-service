// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { VRFHandler } from "src/VRFHandler.sol";
import { VRFHandlerTest } from "test/VRFHandler.t.sol";

/// @title Tests for VRFHandler constructor
contract VRFHandlerTest_Constructor is VRFHandlerTest {
  /// @notice Test successful constructor initialization
  function test_constructor_success() public {
    // Verify the VRF configuration was set correctly
    // Call active requests - should be 0
    assertEq(vrfHandler.activeRequests(), 0);

    // Verify the owner is set correctly
    assertEq(vrfHandler.owner(), deployer);

    // Verify the receiver is an allowed requester
    assertTrue(vrfHandler.allowedRequesters(address(receiver)));
  }

  /// @notice Test constructor reverts with invalid coordinator
  function test_constructor_revert_invalidCoordinator() public {
    vm.startPrank(deployer);
    // Use a generic expectRevert
    vm.expectRevert();

    new VRFHandler(
      address(0), // Invalid coordinator address
      KEY_HASH,
      SUBSCRIPTION_ID,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NATIVE_PAYMENT_ENABLED
    );

    vm.stopPrank();
  }

  /// @notice Test constructor reverts with invalid key hash
  function test_constructor_revert_invalidKeyHash() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);

    new VRFHandler(
      address(coordinator),
      bytes32(0), // Invalid key hash
      SUBSCRIPTION_ID,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NATIVE_PAYMENT_ENABLED
    );

    vm.stopPrank();
  }

  /// @notice Test constructor reverts with invalid subscription ID
  function test_constructor_revert_invalidSubscriptionId() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);

    new VRFHandler(
      address(coordinator),
      KEY_HASH,
      0, // Invalid subscription ID
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NATIVE_PAYMENT_ENABLED
    );

    vm.stopPrank();
  }

  /// @notice Test constructor reverts with invalid callback gas limit
  function test_constructor_revert_invalidCallbackGasLimit() public {
    vm.startPrank(deployer);
    vm.expectRevert(VRFHandler.InvalidParameter.selector);

    new VRFHandler(
      address(coordinator),
      KEY_HASH,
      SUBSCRIPTION_ID,
      REQUEST_CONFIRMATIONS,
      0, // Invalid callback gas limit
      NATIVE_PAYMENT_ENABLED
    );

    vm.stopPrank();
  }
}
