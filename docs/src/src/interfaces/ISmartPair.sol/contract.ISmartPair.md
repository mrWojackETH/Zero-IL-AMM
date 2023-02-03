# ISmartPair

## Functions
### token0


```solidity
function token0() external view returns (address);
```

### token1


```solidity
function token1() external view returns (address);
```

### reserves0


```solidity
function reserves0() external view returns (uint256);
```

### reserves1


```solidity
function reserves1() external view returns (uint256);
```

### swap


```solidity
function swap(bool token0In, uint256 dx) external returns (uint256 dy);
```

### addLiquidity


```solidity
function addLiquidity(bool isToken0, uint256 amount) external returns (uint256 shares);
```

### orderBook


```solidity
function orderBook(Side side) external view returns (order[] memory);
```

### removeLiquidity


```solidity
function removeLiquidity() external returns (uint256 shares);
```

## Structs
### order

```solidity
struct order {
    Option option;
    address investor;
    uint256 amount;
    uint256 fulfilled;
}
```

## Enums
### Side

```solidity
enum Side {
    DEPOSIT0_REMOVE1,
    REMOVE0_DEPOSIT1
}
```

### Option

```solidity
enum Option {
    REMOVE,
    DEPOSIT
}
```

