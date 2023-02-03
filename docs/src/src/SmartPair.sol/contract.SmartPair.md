# SmartPair

## State Variables
### factory

```solidity
address public factory;
```


### _token0

```solidity
IERC20 private _token0;
```


### _token1

```solidity
IERC20 private _token1;
```


### reserves0

```solidity
uint256 public reserves0;
```


### reserves1

```solidity
uint256 public reserves1;
```


### balances

```solidity
mapping(address => mapping(IERC20 => uint256)) public balances;
```


### orders

```solidity
mapping(Side => order[]) private orders;
```


## Functions
### constructor


```solidity
constructor();
```

### _init


```solidity
function _init(address a, address b) external;
```

### token0


```solidity
function token0() public view returns (address);
```

### token1


```solidity
function token1() public view returns (address);
```

### swap


```solidity
function swap(bool token0In, uint256 dx) external returns (uint256 dy);
```

### addLiquidity


```solidity
function addLiquidity(bool isToken0, uint256 amount) external returns (uint256 shares);
```

### removeLiquidity


```solidity
function removeLiquidity(bool isToken0, uint256 amount) external returns (uint256 withdraw);
```

### orderBook


```solidity
function orderBook(Side side) external view returns (order[] memory);
```

### removeLiquidity


```solidity
function removeLiquidity() external returns (uint256 shares);
```

### _mint


```solidity
function _mint(address sender, IERC20 token, uint256 amount) private;
```

### _burn


```solidity
function _burn(address sender, IERC20 token, uint256 amount) private;
```

### _update


```solidity
function _update() private;
```

### _cleanUp


```solidity
function _cleanUp(order[] storage _orders) private;
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

