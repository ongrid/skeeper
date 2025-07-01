// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {IERC1271} from "@openzeppelin-contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract SKeeper is AccessControl, IERC1271 {
    using SafeERC20 for IERC20;

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    constructor(address _admin, address _signer) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
        _grantRole(SIGNER_ROLE, _signer);
    }

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
