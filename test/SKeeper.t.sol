// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SKeeper} from "../src/SKeeper.sol";
import {MockToken} from "./mock/MockToken.sol";

contract SkeeperTest is Test {
    SKeeper public skeeper;
    MockToken public token;
    uint256 amount = 1 ether;

    function setUp() public {
        token = new MockToken(1 ether, 18);
        skeeper = new SKeeper();
        token.transfer(address(skeeper), amount);
        deal(address(skeeper), amount);
    }

    function test_Ether_Withdraw() public {
        address admin = makeAddr("admin");
        vm.prank(admin);
        skeeper.withdraw(address(0), amount);
        assertEq(admin.balance, amount);
    }

    function test_Erc20_Withdraw() public {
        address admin = makeAddr("admin");
        vm.prank(admin);
        skeeper.withdraw(address(token), amount);

        // Verify balances after withdrawal
        assertEq(token.balanceOf(address(skeeper)), 0);
        assertEq(token.balanceOf(admin), amount);
    }
}
