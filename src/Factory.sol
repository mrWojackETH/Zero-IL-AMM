//SPDX-License-Identifier : MIT
pragma solidity ^0.8.12;

import "./SmartPair.sol";

contract Factory {
    mapping(address => mapping(address => address)) private _getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns (bool) {
        require(tokenA != tokenB, "Same addresses");
        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");
        require(_getPair[tokenA][tokenB] == address(0), "Pair exists");
        bytes32 _salt = keccak256(abi.encodePacked(tokenA, tokenB));
        address newPair = address(new SmartPair{salt:_salt}());
        SmartPair(newPair)._init(tokenA, tokenB);
        _getPair[tokenA][tokenB] = newPair;
        _getPair[tokenB][tokenA] = newPair;
        allPairs.push(newPair);
        return true;
    }

    function getPair(address token0, address token1) public view returns (address) {
        return _getPair[token0][token1];
    }
}
