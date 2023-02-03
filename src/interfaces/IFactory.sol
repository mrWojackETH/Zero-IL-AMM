//SPDX-License-Identifier : MIT
pragma solidity ^0.8.12;

interface IFactory {
    function getPair(address token0, address token1) external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (bool);
}
