# SmartRouter

## State Variables
### factory

```solidity
IFactory public factory;
```


## Functions
### checkDeadline


```solidity
modifier checkDeadline(uint256 deadline);
```

### constructor


```solidity
constructor(address _factory);
```

### addLiquidity


```solidity
function addLiquidity(address token0, address token1, bool depositToken0, uint256 amount, uint256 minShares)
    external
    returns (uint256);
```

### swapSingle


```solidity
function swapSingle(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline)
    external
    checkDeadline(deadline)
    returns (uint256);
```

### swapMultiHop


```solidity
function swapMultiHop(
    address[] memory route,
    uint256[] memory amountsIn,
    uint256[] memory minAmountsOut,
    uint256 deadline
) external checkDeadline(deadline) returns (uint256[] memory);
```

### getAmountOut


```solidity
function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256);
```

### getPair


```solidity
function getPair(address token0, address token1) external view returns (address, uint256, uint256);
```

