// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SKeeper} from "../src/SKeeper.sol";

contract SkeeperTest is Test {
    SKeeper public skeeper;

    function setUp() public {
        skeeper = new SKeeper();
        payable(address(skeeper)).transfer(1 ether);
    }

    function test_Withdraw() public {
        address admin = makeAddr("admin");
        vm.prank(admin);
        skeeper.withdraw(address(0), 1);
        assertEq(admin.balance, 1);
    }
}
