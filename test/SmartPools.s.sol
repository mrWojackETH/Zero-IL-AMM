// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/SmartRouter.sol";
import "../src/Factory.sol";
import "../src/SmartPair.sol";
import "../src/mock.sol";

contract SmartPoolTest is Test {
    address public constant bob = address(0x1);
    address public constant alice = address(0x2);
    address public constant jeff = address(0x3);

    mockToken[] public tokens;
    Factory public factory;
    SmartRouter public router;

    //Generate 50 tokens and create all possible pairs in factory
    function setUp() public {
        factory = new Factory();
        for (uint256 i = 0; i < 10; i++) {
            tokens.push(new mockToken("testToken", "TT"));
        }
        factory.createPair(address(tokens[0]), address(tokens[1]));
        factory.createPair(address(tokens[0]), address(tokens[2]));
        factory.createPair(address(tokens[0]), address(tokens[3]));
        factory.createPair(address(tokens[0]), address(tokens[4]));
        factory.createPair(address(tokens[0]), address(tokens[5]));
        factory.createPair(address(tokens[0]), address(tokens[6]));
        factory.createPair(address(tokens[0]), address(tokens[7]));
        factory.createPair(address(tokens[0]), address(tokens[8]));
        factory.createPair(address(tokens[0]), address(tokens[9]));

        factory.createPair(address(tokens[1]), address(tokens[2]));
        factory.createPair(address(tokens[1]), address(tokens[3]));
        factory.createPair(address(tokens[1]), address(tokens[4]));
        factory.createPair(address(tokens[1]), address(tokens[5]));
        factory.createPair(address(tokens[1]), address(tokens[6]));
        factory.createPair(address(tokens[1]), address(tokens[7]));
        factory.createPair(address(tokens[1]), address(tokens[8]));
        factory.createPair(address(tokens[1]), address(tokens[9]));

        factory.createPair(address(tokens[2]), address(tokens[3]));
        factory.createPair(address(tokens[2]), address(tokens[4]));
        factory.createPair(address(tokens[2]), address(tokens[5]));
        factory.createPair(address(tokens[2]), address(tokens[6]));
        factory.createPair(address(tokens[2]), address(tokens[7]));
        factory.createPair(address(tokens[2]), address(tokens[8]));
        factory.createPair(address(tokens[2]), address(tokens[9]));

        factory.createPair(address(tokens[3]), address(tokens[4]));
        factory.createPair(address(tokens[3]), address(tokens[5]));
        factory.createPair(address(tokens[3]), address(tokens[6]));
        factory.createPair(address(tokens[3]), address(tokens[7]));
        factory.createPair(address(tokens[3]), address(tokens[8]));
        factory.createPair(address(tokens[3]), address(tokens[9]));

        factory.createPair(address(tokens[4]), address(tokens[5]));
        factory.createPair(address(tokens[4]), address(tokens[6]));
        factory.createPair(address(tokens[4]), address(tokens[7]));
        factory.createPair(address(tokens[4]), address(tokens[8]));
        factory.createPair(address(tokens[4]), address(tokens[9]));

        factory.createPair(address(tokens[5]), address(tokens[6]));
        factory.createPair(address(tokens[5]), address(tokens[7]));
        factory.createPair(address(tokens[5]), address(tokens[8]));
        factory.createPair(address(tokens[5]), address(tokens[9]));

        factory.createPair(address(tokens[6]), address(tokens[7]));
        factory.createPair(address(tokens[6]), address(tokens[8]));
        factory.createPair(address(tokens[6]), address(tokens[9]));

        factory.createPair(address(tokens[7]), address(tokens[8]));
        factory.createPair(address(tokens[7]), address(tokens[9]));

        factory.createPair(address(tokens[8]), address(tokens[9]));

        router = new SmartRouter(address(factory));
    }

    function test_get_pair(uint256 x, uint256 y) public {
        vm.assume(x != y);
        vm.assume(x < tokens.length && y < tokens.length);
        router.getPair(address(tokens[0]), address(tokens[1]));
    }

    function test_reserves_are_empty() public {
        address t0 = address(tokens[0]);
        address t1 = address(tokens[1]);
        (address p, uint256 r0, uint256 r1) = router.getPair(t0, t1);
        assertEq(r0, 0);
        assertEq(r1, 0);
    }

    function test_add_liquidity_first(uint256 x, uint256 y, uint256 a) public {
        vm.assume(x != y && x < y);
        vm.assume(x < tokens.length && y < tokens.length);
        vm.assume(a < 2 ** 255 && a > 0);
        tokens[x].mint(a);
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a), a);
        emit log_named_uint("Balance : ", tokens[x].balanceOf(address(pair)));
    }

    function test_add_liquidity_second(uint256 x, uint256 y, uint256 a) public {
        vm.assume(x != y && x < y);
        vm.assume(x < tokens.length && y < tokens.length);
        vm.assume(a < 2 ** 255 && a > 0);

        vm.startPrank(bob);

        tokens[x].mint(a);
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a), a);
        assertEq(tokens[x].balanceOf(address(pair)), a);

        vm.stopPrank();

        vm.startPrank(alice);

        tokens[x].mint(a);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a), 0);
        assertEq(tokens[x].balanceOf(address(pair)), 2 * a);
        SmartPair.Side s = SmartPair.Side.DEPOSIT0_REMOVE1;
        SmartPair.order[] memory orders = pair.orderBook(s);
        assertEq(orders[0].amount, a);
        assertEq(orders[0].fulfilled, 0);
        emit log_uint(a);
        emit log_uint(orders[0].amount);
        emit log_uint(orders[0].fulfilled);

        vm.stopPrank();
    }

    function test_fulfill_liquidity_orders(uint256 x, uint256 y, uint256 a) public {
        vm.assume(x != y && x < y);
        vm.assume(x < tokens.length && y < tokens.length);
        vm.assume(a < 2 ** 255 && a > 0);

        tokens[x].mint(a);
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a), a);
        assertEq(tokens[x].balanceOf(address(pair)), a);

        tokens[x].mint(a);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a), 0);
        assertEq(tokens[x].balanceOf(address(pair)), 2 * a);
        SmartPair.Side s = SmartPair.Side.DEPOSIT0_REMOVE1;
        SmartPair.order[] memory orders = pair.orderBook(s);
        assertEq(orders[0].amount, a);
        assertEq(orders[0].fulfilled, 0);

        tokens[y].mint(a);
        tokens[y].approve(address(pair), a);
        assertEq(pair.addLiquidity(false, a), 0);
        assertEq(tokens[y].balanceOf(address(pair)), a);
        orders = pair.orderBook(s);
        assertGt(orders[0].fulfilled, 0);
    }

    function test_swap(uint256 a) public {
        uint256 amount = 500000e18;
        vm.assume(a < amount && a > 0);
        mockToken token0 = tokens[5];
        mockToken token1 = tokens[8];

        //deposit token0 as Bob
        vm.startPrank(bob);
        token0.mint(amount);
        (address pAddress,,) = router.getPair(address(token0), address(token1));
        token0.approve(pAddress, amount);
        SmartPair pair = SmartPair(pAddress);
        pair.addLiquidity(true, amount);
        vm.stopPrank();

        //deposit token1 as Alice

        vm.startPrank(alice);
        token1.mint(amount);
        token1.approve(pAddress, amount);
        pair.addLiquidity(false, amount);
        vm.stopPrank();

        //jeff performs a swap

        vm.startPrank(jeff);
        token0.mint(a);
        token0.approve(address(router), a);
        uint256 amountOutAprox = router.getAmountOut(address(token0), address(token1), a);
        emit log_uint(amountOutAprox);
        emit log_uint(router.swapSingle(address(token0), address(token1), a, 0, block.timestamp));
    }

    function test_time_expired() public {
        mockToken token0 = tokens[5];
        mockToken token1 = tokens[8];
        uint256 time = block.timestamp;
        vm.roll(500);
        token0.mint(100);
        token0.approve(address(router), 100);
        uint256 amountOutAprox = router.getAmountOut(address(token0), address(token1), 100);
        vm.expectRevert("TIME_EXPIRED");
        router.swapSingle(address(token0), address(token1), 100, 0, time    );
        
    }
}
