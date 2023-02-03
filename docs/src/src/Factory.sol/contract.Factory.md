# Factory

## State Variables
### _getPair

```solidity
mapping(address => mapping(address => address)) private _getPair;
```


### allPairs

```solidity
address[] public allPairs;
```


## Functions
### createPair


```solidity
function createPair(address tokenA, address tokenB) external returns (bool);
```

### getPair


```solidity
function getPair(address token0, address token1) public view returns (address);
```

