// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

library utils {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
        return x > y ? (x, y) : (y, x);
    }
}

contract SmartPair {
    address public factory;

    using utils for uint256;

    IERC20 private _token0;
    IERC20 private _token1;
    uint256 public reserves0;
    uint256 public reserves1;
    mapping(address => mapping(IERC20 => uint256)) public balances;
    mapping(Side => order[]) private orders;

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

    constructor() {
        factory = msg.sender;
    }

    function _init(address a, address b) external {
        require(msg.sender == factory, "caller!=factory");
        _token0 = IERC20(a);
        _token1 = IERC20(b);
    }

    function token0() public view returns (address) {
        return address(_token0);
    }

    function token1() public view returns (address) {
        return address(_token1);
    }

    function swap(bool token0In, uint256 dx) external returns (uint256 dy) {
        require(dx > 0, "dx=0");
        (IERC20 tokenIn, IERC20 tokenOut) = (token0In ? _token0 : _token1, !token0In ? _token0 : _token1);
        (uint256 reserveIn, uint256 reserveOut) =
            ((token0In ? reserves0 : reserves1, !token0In ? reserves0 : reserves1));
        tokenIn.transferFrom(msg.sender, address(this), dx);
        uint256 amountInAfterFee = dx * 997 / 1000;
        dy = (reserveOut * amountInAfterFee) / (reserveIn + amountInAfterFee);
        tokenOut.transfer(msg.sender, dy);
        _update();
    }

    function addLiquidity(bool isToken0, uint256 amount) external returns (uint256 shares) {
        require(amount > 0, "amount=0");
        (IERC20 token, IERC20 counterToken) = isToken0 ? (_token0, _token1) : (_token1, _token1);
        (uint256 reserves, uint256 counterReserves) = isToken0 ? (reserves0, reserves1) : (reserves1, reserves0);
        (Side side, Side counterSide) =
            (isToken0 ? (Side.DEPOSIT0_REMOVE1, Side.REMOVE0_DEPOSIT1) : (Side.REMOVE0_DEPOSIT1, Side.DEPOSIT0_REMOVE1));

        uint256 orderFulfilled;
        order[] storage counterOrders = orders[counterSide];
        uint256 l = counterOrders.length;
        token.transferFrom(msg.sender, address(this), amount);

        if (reserves == 0 && counterReserves == 0) {
            _update();
            _mint(msg.sender, token, amount);
            shares = amount;
            // CASE HE IS THE FIRST ONE
        } else {
            for (uint256 i = 0; i < l; i++) {
                order memory o = counterOrders[i];
                if (o.option == Option.REMOVE) {
                    if (o.amount - o.fulfilled > amount - orderFulfilled) {
                        counterOrders[i].fulfilled += amount - orderFulfilled;
                        _burn(o.investor, token, amount - orderFulfilled);
                        orderFulfilled = amount;
                        //CASE HE DEPOSITS EVERYTHING
                        break;
                    } else {
                        orderFulfilled += (o.amount - o.fulfilled);
                        _burn(o.investor, token, amount - orderFulfilled);
                        counterOrders[i].fulfilled = counterOrders[i].amount;
                        //CASE HE DOESNT
                    }
                }

                if (o.option == Option.DEPOSIT) {
                    uint256 amountProportionAdjusted = o.amount * reserves / counterReserves;
                    uint256 fulfilledProportionAdjusted = o.fulfilled * reserves / counterReserves;

                    if (amountProportionAdjusted - fulfilledProportionAdjusted > amount - orderFulfilled) {
                        counterOrders[i].fulfilled += amount - orderFulfilled;
                        _mint(o.investor, counterToken, amount - orderFulfilled);
                        orderFulfilled = amount;
                        //CASE HE DEPOSITS EVERYTHING
                        break;
                    } else {
                        orderFulfilled += (amountProportionAdjusted - fulfilledProportionAdjusted);
                        _mint(o.investor, counterToken, (amount - orderFulfilled));
                        counterOrders[i].fulfilled = o.amount;
                        //CASE HE DOESNT
                    }
                }

                if (orderFulfilled == amount) break;
            }

            shares = orderFulfilled;
            _mint(msg.sender, token, shares);

            if (orderFulfilled < amount) {
                orders[side].push(
                    order({option: Option.DEPOSIT, investor: msg.sender, amount: amount - orderFulfilled, fulfilled: 0})
                );
            }

            _cleanUp(counterOrders);
        }
    }

    function removeLiquidity(bool isToken0, uint256 amount) external returns (uint256 withdraw) {
        (IERC20 token, IERC20 counterToken) = isToken0 ? (_token0, _token1) : (_token1, _token1);
        require(balances[msg.sender][token] >= amount, "insufficient balance");
        (uint256 reserves, uint256 counterReserves) = isToken0 ? (reserves0, reserves1) : (reserves1, reserves0);
        (Side side, Side counterSide) = (
            !isToken0 ? (Side.DEPOSIT0_REMOVE1, Side.REMOVE0_DEPOSIT1) : (Side.REMOVE0_DEPOSIT1, Side.DEPOSIT0_REMOVE1)
        );

        uint256 orderFulfilled;
        order[] storage counterOrders = orders[counterSide];
        uint256 l = counterOrders.length;

        for (uint256 i = 0; i < l; i++) {
            order memory o = counterOrders[i];
            if (o.option == Option.DEPOSIT) {
                if (o.amount - o.fulfilled > amount - orderFulfilled) {
                    counterOrders[i].fulfilled += amount - orderFulfilled;
                    _mint(o.investor, token, amount - orderFulfilled);
                    orderFulfilled = amount;
                    //CASE HE DEPOSITS EVERYTHING
                    break;
                } else {
                    orderFulfilled += (o.amount - o.fulfilled);
                    _mint(o.investor, token, amount - orderFulfilled);
                    counterOrders[i].fulfilled = counterOrders[i].amount;
                    //CASE HE DOESNT
                }
            }

            if (o.option == Option.REMOVE) {
                uint256 amountProportionAdjusted = o.amount * reserves / counterReserves;
                uint256 fulfilledProportionAdjusted = o.fulfilled * reserves / counterReserves;

                if (amountProportionAdjusted - fulfilledProportionAdjusted > amount - orderFulfilled) {
                    counterOrders[i].fulfilled += amount - orderFulfilled;
                    _burn(o.investor, counterToken, amount - orderFulfilled);
                    orderFulfilled = amount;
                    //CASE HE DEPOSITS EVERYTHING
                    break;
                } else {
                    orderFulfilled += (amountProportionAdjusted - fulfilledProportionAdjusted);
                    _burn(o.investor, counterToken, (amount - orderFulfilled));
                    counterOrders[i].fulfilled = o.amount;
                    //CASE HE DOESNT
                }
            }

            if (orderFulfilled == amount) break;
        }
        withdraw = orderFulfilled;
        _burn(msg.sender, token, withdraw);

        if (orderFulfilled < amount) {
            orders[side].push(
                order({option: Option.REMOVE, investor: msg.sender, amount: amount - orderFulfilled, fulfilled: 0})
            );
        }

        _cleanUp(counterOrders);
    }

    function orderBook(Side side) external view returns (order[] memory) {
        return orders[side];
    }

    function removeLiquidity() external returns (uint256 shares) {}

    function _mint(address sender, IERC20 token, uint256 amount) private {
        balances[sender][token] += amount;
    }

    function _burn(address sender, IERC20 token, uint256 amount) private {
        balances[sender][token] -= amount;
        token.transfer(sender, amount);
    }

    function _update() private {
        reserves0 = _token0.balanceOf(address(this));
        reserves1 = _token1.balanceOf(address(this));
    }

    function _cleanUp(order[] storage _orders) private {
        while (_orders.length > 1 && _orders[0].fulfilled == _orders[0].amount) {
            for (uint256 i = 0; i < _orders.length - 1; i++) {
                _orders[i] = _orders[i + 1];
            }
            _orders.pop();
        }
    }
}
