// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats, StdUtils } from "forge-std/Test.sol";

abstract contract BaseTest is PRBTest, StdCheats, StdUtils {
  struct Users {
    address payable owner;
    address payable notOwner;
  }

  Users public users;
  mapping(address token => mapping(address user => uint256 balance)) public initialBalances;

  /**
   * @notice Asserts that the balance of `user`, in ERC20 or native tokens
   * has changed by `amount` after executing the function.
   * @dev For use with different paramenters, call the modifier multiple times.
   */
  modifier assertBalanceChange(address token, address user, int256 amount) {
    // Store initial balance.
    if (token == address(0)) initialBalances[token][user] = user.balance;
    else initialBalances[token][user] = IERC20(token).balanceOf(user);

    // Execute function.
    _;

    // Check post-execution balances.
    uint256 currentBalance;
    if (token == address(0)) currentBalance = user.balance;
    else currentBalance = IERC20(token).balanceOf(user);
    uint256 expectedBalance = uint256(int256(initialBalances[token][user]) + amount);
    assertEq(currentBalance, expectedBalance);
  }

  function setUp() public virtual {
    users = Users(createUser("owner"), createUser("notOwner"));

    // Prank owner by default
    vm.startPrank(users.owner);
    vm.warp(1_715_968_490);
  }

  /// @dev Creates a new account and funds it with 100 ETH.
  function createUser(string memory name) public returns (address payable addr) {
    addr = payable(makeAddr(name));
    vm.deal(addr, 100 ether);
  }
}
