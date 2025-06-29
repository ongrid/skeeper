// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract SKeeper {
    using SafeERC20 for IERC20;

    receive() external payable {}

    /**
     * @notice Withdraws a specified amount of a given token from SKeeper's balance
     * @param token The ERC20 token to withdraw. If the address is zero, withdraws native token (ETH).
     * @param amount The amount of the token to withdraw.
     */
    function withdraw(address token, uint256 amount) external {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }
}
