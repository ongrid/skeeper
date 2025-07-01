// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SKeeper} from "../src/SKeeper.sol";
import {MockToken} from "./mock/MockToken.sol";
import {IAccessControl} from "@openzeppelin-contracts/access/IAccessControl.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";

contract SkeeperTest is Test {
    SKeeper public skeeper;
    MockToken public token;
    uint256 amount = 1 ether;
    address keeper_eoa;
    bytes32 KEEPER_ROLE = keccak256("KEEPER_ROLE");

    function setUp() public {
        token = new MockToken(1 ether, 18);
        keeper_eoa = makeAddr("keeper_eoa");
        skeeper = new SKeeper(keeper_eoa);
        token.transfer(address(skeeper), amount);
        deal(address(skeeper), amount);
    }

    function test_ApproveReverts_WhenNoKeeperRole() public {
        address stranger_eoa = makeAddr("stranger_eoa");
        vm.startPrank(stranger_eoa);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger_eoa, KEEPER_ROLE)
        );
        skeeper.approve(address(token), address(1), 1);
    }

    function test_WithdrawReverts_WhenNoKeeperRole() public {
        address stranger_eoa = makeAddr("stranger_eoa");
        vm.startPrank(stranger_eoa);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(0), amount);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(token), amount);
    }

    function test_WithdrawReverts_AfterKeeperRoleRevoked() public {
        vm.startPrank(keeper_eoa);

        // withdrawal works for keeper_eoa initially
        skeeper.withdraw(address(token), 1);
        skeeper.withdraw(address(0), 1);

        // After revocation of KEEPER_ROLE
        // keeper_eoa should not be able to withdraw
        skeeper.revokeRole(KEEPER_ROLE, keeper_eoa);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, keeper_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(0), 1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, keeper_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(token), 1);
    }

    function test_WithdrawSuccess_AfterKeeperRoleGranted() public {
        address stranger_eoa = makeAddr("stranger_eoa");
        vm.startPrank(stranger_eoa);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(0), amount);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger_eoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(token), amount);

        // Ensure stranger_eoa can't grant themselves KEEPER_ROLE
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                stranger_eoa,
                bytes32(0) // DEFAULT_ADMIN_ROLE is 0x00
            )
        );
        skeeper.grantRole(KEEPER_ROLE, stranger_eoa);

        // Grant KEEPER_ROLE to stranger_eoa from keeper_eoa
        vm.startPrank(keeper_eoa);
        skeeper.grantRole(KEEPER_ROLE, stranger_eoa);

        // Now stranger_eoa can withdraw
        vm.startPrank(stranger_eoa);
        skeeper.withdraw(address(token), amount);
        assertEq(token.balanceOf(stranger_eoa), amount);
        skeeper.withdraw(address(0), amount);
        assertEq(stranger_eoa.balance, amount);
    }

    function test_Erc20_WithdrawSuccess() public {
        vm.prank(keeper_eoa);
        skeeper.withdraw(address(token), amount);

        // Verify balances after withdrawal
        assertEq(token.balanceOf(address(skeeper)), 0);
        assertEq(token.balanceOf(keeper_eoa), amount);
    }

    function test_Ether_WithdrawSuccess() public {
        vm.prank(keeper_eoa);
        skeeper.withdraw(address(0), amount);
        assertEq(keeper_eoa.balance, amount);
    }

    function test_Erc20_ApprovedSpendSuccess() public {
        address spender_eoa = makeAddr("spender_eoa");
        vm.startPrank(keeper_eoa);
        assertEq(token.allowance(address(skeeper), spender_eoa), 0);
        skeeper.approve(address(token), spender_eoa, amount);

        // Verify that the spender has been approved
        assertEq(token.allowance(address(skeeper), spender_eoa), amount);

        // Now spender_eoa can transfer tokens from skeeper to itself
        vm.startPrank(spender_eoa);
        token.transferFrom(address(skeeper), spender_eoa, amount);
        assertEq(token.balanceOf(spender_eoa), amount);
        assertEq(token.balanceOf(address(skeeper)), 0);
    }
}
