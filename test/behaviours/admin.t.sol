// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

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

  /// @notice Test setting native payment enabled
  function test_setNativePaymentEnabled_success() public {
    vm.startPrank(deployer);

    // Expect event emission
    vm.expectEmit(false, false, false, true);
    emit NativePaymentEnabledSet(true);

    // Set native payment enabled
    vrfHandler.setNativePaymentEnabled(true);
    vm.stopPrank();

    // Verify via getVrfConfig
    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();
    assertTrue(config.nativePaymentEnabled);
  }

  /// @notice Test revert when non-owner tries to set native payment enabled
  function test_setNativePaymentEnabled_revert_notOwner() public {
    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.setNativePaymentEnabled(true);
    vm.stopPrank();
  }

  /// @notice Test setting VRF config
  function test_setVrfConfig_success() public {
    bytes32 newKeyHash = bytes32(uint256(2));
    uint256 newSubscriptionId = 100;
    uint16 newRequestConfirmations = 10;
    uint32 newCallbackGasLimit = 1_000_000;
    bool newNativePaymentEnabled = true;

    vm.startPrank(deployer);

    // Set new VRF config
    vrfHandler.setVrfConfig(
      newKeyHash, newSubscriptionId, newRequestConfirmations, newCallbackGasLimit, newNativePaymentEnabled
    );
    vm.stopPrank();

    // Verify via getVrfConfig
    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();
    assertEq(config.keyHash, newKeyHash);
    assertEq(config.subscriptionId, newSubscriptionId);
    assertEq(config.requestConfirmations, newRequestConfirmations);
    assertEq(config.callbackGasLimit, newCallbackGasLimit);
    assertTrue(config.nativePaymentEnabled);
  }

  /// @notice Test revert when non-owner tries to set VRF config
  function test_setVrfConfig_revert_notOwner() public {
    vm.startPrank(randomUser);
    vm.expectRevert();
    vrfHandler.setVrfConfig(bytes32(uint256(2)), 100, 10, 1_000_000, true);
    vm.stopPrank();
  }

  /// @notice Test getVrfConfig returns correct initial values
  function test_getVrfConfig_success() public view {
    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();

    assertEq(config.keyHash, KEY_HASH);
    assertEq(config.subscriptionId, SUBSCRIPTION_ID);
    assertEq(config.requestConfirmations, REQUEST_CONFIRMATIONS);
    assertEq(config.callbackGasLimit, CALLBACK_GAS_LIMIT);
    assertEq(config.nativePaymentEnabled, NATIVE_PAYMENT_ENABLED);
  }

  /// @notice Fuzz test for setRequestConfirmations
  function testFuzz_setRequestConfirmations(uint16 confirmations) public {
    vm.startPrank(deployer);
    vrfHandler.setRequestConfirmations(confirmations);
    vm.stopPrank();

    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();
    assertEq(config.requestConfirmations, confirmations);
  }

  /// @notice Fuzz test for setCallbackGasLimit
  function testFuzz_setCallbackGasLimit(uint32 gasLimit) public {
    vm.assume(gasLimit > 0);

    vm.startPrank(deployer);
    vrfHandler.setCallbackGasLimit(gasLimit);
    vm.stopPrank();

    VRFHandler.VRFConfig memory config = vrfHandler.getVrfConfig();
    assertEq(config.callbackGasLimit, gasLimit);
  }

  /// @notice Test adding and removing multiple requesters
  function test_addRemoveMultipleRequesters() public {
    address requester1 = makeAddr("requester1");
    address requester2 = makeAddr("requester2");
    address requester3 = makeAddr("requester3");

    vm.startPrank(deployer);

    // Add multiple requesters
    vrfHandler.addAllowedRequester(requester1);
    vrfHandler.addAllowedRequester(requester2);
    vrfHandler.addAllowedRequester(requester3);

    assertTrue(vrfHandler.allowedRequesters(requester1));
    assertTrue(vrfHandler.allowedRequesters(requester2));
    assertTrue(vrfHandler.allowedRequesters(requester3));

    // Remove one requester
    vrfHandler.removeAllowedRequester(requester2);

    assertTrue(vrfHandler.allowedRequesters(requester1));
    assertFalse(vrfHandler.allowedRequesters(requester2));
    assertTrue(vrfHandler.allowedRequesters(requester3));

    vm.stopPrank();
  }
}
