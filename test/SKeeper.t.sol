// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SKeeper} from "../src/SKeeper.sol";
import {MockToken} from "./mock/MockToken.sol";
import {IAccessControl} from "@openzeppelin-contracts/access/IAccessControl.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {ECDSA} from "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract SkeeperTest is Test {
    SKeeper public skeeper;
    MockToken public token;
    uint256 amount = 1 ether;
    address keeperEoa;
    bytes32 KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // The address of the signer EOA, which is used to sign the hash
    // derived from well-known mnemonic phrase at index 0
    // "test test test test test test test test test test test junk"
    address signerEoa = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // See: https://liquorice.gitbook.io/liquorice-docs/for-market-makers/basic-market-making-api
    bytes32 signedHash = hex"2342c2e81befd9dda11c9e769d6d867e347d5b84a0137bf9fa31acbe7ee4f5ac";
    // Signature for the signedHash, generated using the private key of signerEoa
    bytes signature =
        hex"1b75c9b69ce85146226ee957e1cac793ce7ea7544313909a8dd6a6afdbb348fd411480c829a6a7f73eb16bd48253f4cee567301f71890aab897aa007a5d4a5571b";

    function setUp() public {
        token = new MockToken(1 ether, 18);
        keeperEoa = makeAddr("keeperEoa");
        skeeper = new SKeeper(keeperEoa, signerEoa);
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
        vm.startPrank(keeperEoa);

        // withdrawal works for keeperEoa initially
        skeeper.withdraw(address(token), 1);
        skeeper.withdraw(address(0), 1);

        // After revocation of KEEPER_ROLE
        // keeperEoa should not be able to withdraw
        skeeper.revokeRole(KEEPER_ROLE, keeperEoa);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, keeperEoa, KEEPER_ROLE)
        );
        skeeper.withdraw(address(0), 1);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, keeperEoa, KEEPER_ROLE)
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

        // Grant KEEPER_ROLE to stranger_eoa from keeperEoa
        vm.startPrank(keeperEoa);
        skeeper.grantRole(KEEPER_ROLE, stranger_eoa);

        // Now stranger_eoa can withdraw
        vm.startPrank(stranger_eoa);
        skeeper.withdraw(address(token), amount);
        assertEq(token.balanceOf(stranger_eoa), amount);
        skeeper.withdraw(address(0), amount);
        assertEq(stranger_eoa.balance, amount);
    }

    function test_Erc20_WithdrawSuccess() public {
        vm.prank(keeperEoa);
        skeeper.withdraw(address(token), amount);

        // Verify balances after withdrawal
        assertEq(token.balanceOf(address(skeeper)), 0);
        assertEq(token.balanceOf(keeperEoa), amount);
    }

    function test_Ether_WithdrawSuccess() public {
        vm.prank(keeperEoa);
        skeeper.withdraw(address(0), amount);
        assertEq(keeperEoa.balance, amount);
    }

    function test_Erc20_ApprovedSpendSuccess() public {
        address spender_eoa = makeAddr("spender_eoa");
        vm.startPrank(keeperEoa);
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

    function test_IsValidSignatureSuccess() public {
        vm.prank(keeperEoa);
        skeeper.grantRole(SIGNER_ROLE, signerEoa);
        assertTrue(skeeper.hasRole(SIGNER_ROLE, signerEoa));
        assertEq(skeeper.isValidSignature(signedHash, signature), skeeper.isValidSignature.selector);
    }

    function test_IsValidSignature_WhenNoSignerRole() public {
        // Revoke signer role from signerEoa
        assertTrue(skeeper.hasRole(SIGNER_ROLE, signerEoa));
        vm.prank(keeperEoa);
        skeeper.revokeRole(SIGNER_ROLE, signerEoa);
        assertFalse(skeeper.hasRole(SIGNER_ROLE, signerEoa));
        // isValidSignature should return 0x00 that means negative result
        assertEq(skeeper.isValidSignature(signedHash, signature), bytes4(0));
    }

    function test_IsValidSignature_WhenWrongSingatureValue() public {
        bytes memory wrongSignature =
            hex"deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefde";
        vm.expectPartialRevert(ECDSA.ECDSAInvalidSignatureS.selector);
        skeeper.isValidSignature(signedHash, wrongSignature);
    }

    function test_IsValidSignature_WhenShortSignature() public {
        bytes memory wrongSignature =
            hex"deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef";
        vm.expectRevert(abi.encodeWithSelector(ECDSA.ECDSAInvalidSignatureLength.selector, 64));
        skeeper.isValidSignature(signedHash, wrongSignature);
    }
}
