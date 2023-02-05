// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISmartPair {
    enum Side {
        DEPOSIT0_REMOVE1,
        REMOVE0_DEPOSIT1
    }

    enum Option {
        REMOVE,
        DEPOSIT
    }

    struct order {
        Option option;
        address investor;
        uint256 amount;
        uint256 fulfilled;
    }

    function token0() external view returns (address);
    function token1() external view returns (address);
    function reserves0() external view returns (uint256);
    function reserves1() external view returns (uint256);
    function swap(bool token0In, uint256 dx) external returns (uint256 dy);
    function addLiquidity(bool isToken0, uint256 amount, address to) external returns (uint256 shares);
    function orderBook(Side side) external view returns (order[] memory);
    function removeLiquidity() external returns (uint256 shares);
    function balances(address account, address token) external view returns (uint256);
}
