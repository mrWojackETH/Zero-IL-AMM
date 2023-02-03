//SPDX-License-Identifier: MIT

import "./interfaces/ISmartPair.sol";
import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartRouter {
    modifier checkDeadline(uint256 deadline) {
        require(deadline >= block.timestamp, "Expired");
        _;
    }

    IFactory public factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }

    function addLiquidity(address token0, address token1, bool depositToken0, uint256 amount, uint256 minShares)
        external
        returns (uint256)
    {
        ISmartPair pair = ISmartPair(factory.getPair(token0, token1));
        IERC20 token = IERC20(depositToken0 ? token0 : token1);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(pair), amount);
        bool isToken0 = token0 == pair.token0() ? depositToken0 : !depositToken0;
        uint256 shares = pair.addLiquidity(isToken0, amount);
        require(shares >= minShares, "s<minS");
        return shares;
    }

    /*  function removeLiquidity(address token0, address token1, bool depositToken0, uint256 minShares) external returns (uint256){
        
    }  
    */
    function swapSingle(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline)
        external
        checkDeadline(deadline)
        returns (uint256)
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ISmartPair pair = ISmartPair(factory.getPair(tokenIn, tokenOut));
        bool _isToken0 = tokenIn == pair.token0();
        IERC20(tokenIn).approve(address(pair), amountIn);
        uint256 dy = pair.swap(_isToken0, amountIn);
        require(dy >= minAmountOut, "dy<minDy");
        IERC20(tokenOut).transfer(msg.sender, dy);
        return dy;
    }

    function swapMultiHop(
        address[] memory route,
        uint256[] memory amountsIn,
        uint256[] memory minAmountsOut,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256[] memory) {
        require(route.length == amountsIn.length && amountsIn.length == minAmountsOut.length, "Incorrect params");
        IERC20(route[0]).transferFrom(msg.sender, address(this), amountsIn[0]);
        uint256 l = route.length;
        uint256[] memory dy = new uint256[](l);
        for (uint256 i = 0; i < l - 1;) {
            address _token0 = route[i];
            address _token1 = route[i + 1];
            ISmartPair pair = ISmartPair(factory.getPair(_token0, _token1));
            bool _isToken0 = _token0 == pair.token0();
            require(pair.swap(_isToken0, amountsIn[i]) >= minAmountsOut[i], "dy<minDy");
            unchecked {
                ++i;
            }
        }
        IERC20(route[l]).transfer(msg.sender, dy[l]);
        return dy;
    }

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
        ISmartPair pair = ISmartPair(factory.getPair(tokenIn, tokenOut));
        bool _isToken0 = tokenIn == pair.token0();
        (uint256 reservesIn, uint256 reservesOut) =
            _isToken0 ? (pair.reserves0(), pair.reserves1()) : (pair.reserves1(), pair.reserves1());
        uint256 amountInAfterFee = amountIn * 997 / 10000;
        return (reservesOut * amountInAfterFee / (reservesIn + amountInAfterFee));
    }

    function getPair(address token0, address token1) external view returns (address, uint256, uint256) {
        address pair = factory.getPair(token0, token1);
        ISmartPair instance = ISmartPair(pair);
        uint256 reserves0 = instance.reserves0();
        uint256 reserves1 = instance.reserves1();

        return (pair, reserves0, reserves1);
    }
}
