// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {IERC1271} from "@openzeppelin-contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Signer & Keeper multi-role wallet
 * @notice A multi-role wallet contract for managing assets with role-based access control
 * @dev This contract implements OpenZeppelin's AccessControl for role management and ERC-1271 for signature validation.
 * It provides functionality for:
 * - Role-based asset management (ETH and ERC-20 tokens)
 * - Token approvals for third-party spending
 * - Signature validation for off-chain signed messages
 *
 * Roles:
 * - DEFAULT_ADMIN_ROLE: Can grant/revoke all roles
 * - KEEPER_ROLE: Can withdraw funds and approve token spending
 * - SIGNER_ROLE: Can create valid signatures for ERC-1271 validation
 *
 * @author Kirill Varlamov
 */
contract SKeeper is AccessControl, IERC1271 {
    using SafeERC20 for IERC20;

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /**
     * @notice Constructor to initialize the SKeeper contract with admin and signer roles
     * @param _admin The address of the admin who will have DEFAULT_ADMIN_ROLE and KEEPER_ROLE.
     * @param _signer The address of the signer who will have SIGNER_ROLE only
     */
    constructor(address _admin, address _signer) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
        _grantRole(SIGNER_ROLE, _signer);
    }

    /**
     * @notice Fallback function to receive native tokens (ETH)
     */
    receive() external payable {}

    /**
     * @notice Approves a specified amount of a given token from SKeeper's balance to spender
     * @param token The ERC20 token to approve.
     * @param amount The amount of the token to approve.
     * @param spender The address to which the approval is granted.
     */
    function approve(address token, address spender, uint256 amount) external onlyRole(KEEPER_ROLE) {
        require(token != address(0), "Skeeper: ZERO_TOKEN_ADDRESS");
        IERC20(token).forceApprove(spender, amount);
    }

    /**
     * @notice Withdraws a specified amount of a given token from SKeeper's balance
     * @param token The ERC20 token to withdraw. If the address is zero, withdraws native token (ETH).
     * @param amount The amount of the token to withdraw.
     */
    function withdraw(address token, uint256 amount) external onlyRole(KEEPER_ROLE) {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice EIP-1271 signature validation method.
     * @dev Checks if the provided signature is valid for the given hash.
     * (i.e. that the recovered signer has the SIGNER_ROLE in the verifying contract.)
     * See: https://eips.ethereum.org/EIPS/eip-1271
     * @param hash Hash of message that was signed
     * @param signature  Signature encoded as bytes
     * @return magicValue Returns the magic value if the signature is valid, otherwise returns bytes4(0).
     */
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        address signer = ECDSA.recover(hash, signature);
        return hasRole(SIGNER_ROLE, signer) ? this.isValidSignature.selector : bytes4(0);
    }
}
