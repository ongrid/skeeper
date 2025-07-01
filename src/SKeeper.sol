// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";

contract SKeeper is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
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
}
