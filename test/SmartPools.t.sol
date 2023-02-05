// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "../src/SmartRouter.sol";
import "../src/Factory.sol";
import "../src/SmartPair.sol";
import "../src/mock.sol";

contract SmartPoolTest is Test {
    modifier limitXy(uint256 x, uint256 y) {
        vm.assume(x != y && x < y);
        vm.assume(x < tokens.length && y < tokens.length);
        _;
    }

    address public constant bob = address(0x1);
    address public constant alice = address(0x2);
    address public constant jeff = address(0x3);

    mockToken[] public tokens;
    Factory public factory;
    SmartRouter public router;

    //Generate 10 tokens and create all possible pairs in factory
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

    // for any token pair the pool should not be address 0
    function test_get_pair(uint256 x, uint256 y) public limitXy(x, y) {
        (address pAddress,,) = router.getPair(address(tokens[0]), address(tokens[1]));
        assertTrue(pAddress != address(0));
    }

    // all reserves should be empty
    function test_reserves_are_empty(uint256 x, uint256 y) public limitXy(x, y) {
        address t0 = address(tokens[x]);
        address t1 = address(tokens[y]);
        (address p, uint256 r0, uint256 r1) = router.getPair(t0, t1);
        assertEq(r0, 0);
        assertEq(r1, 0);
        assertEq(IERC20(t0).balanceOf(address(SmartPair(p))), 0);
        assertEq(IERC20(t1).balanceOf(address(SmartPair(p))), 0);
    }
    // add liquidity when pool is empty

    function test_add_liquidity_first(uint256 x, uint256 y, uint256 a) public limitXy(x, y) {
        vm.assume(a < 2 ** 255 && a > 0);
        tokens[x].mint(a);
        uint256 userBalanceBefore = tokens[x].balanceOf(address(this));
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        // should be able to deposit all since usser is the first
        assertEq(pair.addLiquidity(true, a,address(this)), a);
        uint256 userBalanceAfter = tokens[x].balanceOf(address(this));
        // the user should not have "a" tokens already
        assertEq(userBalanceBefore - userBalanceAfter, a);
        // pool should own the tokens now
        assertEq(tokens[x].balanceOf(pAddress), a);
    }

    function test_add_liquidity_second(uint256 x, uint256 y, uint256 a) public limitXy(x, y) {
        vm.assume(a < 2 ** 255 && a > 0);

        // add liquidity first as BOB
        vm.startPrank(bob);
        tokens[x].mint(a);
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        pair.addLiquidity(true, a,bob);
        vm.stopPrank();

        // add Liquidity after as ALICE for same token
        vm.startPrank(alice);
        tokens[x].mint(a);
        tokens[x].approve(address(pair), a);
        assertEq(pair.addLiquidity(true, a,alice), 0);
        // contract should have the tokens
        assertEq(tokens[x].balanceOf(address(pair)), 2 * a);
        SmartPair.Side s = SmartPair.Side.DEPOSIT0_REMOVE1;
        SmartPair.order[] memory orders = pair.orderBook(s);

        //order should be created
        assertEq(orders[0].amount, a);
        assertEq(orders[0].fulfilled, 0);
        //alice should not have any coins deposited yet
        assertEq(pair.balances(alice, address(tokens[x])), 0);
        vm.stopPrank();
    }

    function test_fulfill_liquidity_orders(uint256 a) public {
        uint256 x = 2;
        uint256 y = 5;
        vm.assume(a > 0);
        vm.assume(a < 1000000e18);
        // add liquidity first as BOB
        vm.startPrank(bob);
        tokens[x].mint(a);
        (address pAddress,,) = router.getPair(address(tokens[x]), address(tokens[y]));
        SmartPair pair = SmartPair(pAddress);
        tokens[x].approve(address(pair), a);
        pair.addLiquidity(true, a,bob);
        assertEq(pair.balances(bob, address(tokens[x])), a);
        SmartPair.Side s = SmartPair.Side.DEPOSIT0_REMOVE1;
        SmartPair.order[] memory orders = pair.orderBook(s);
        assertEq(orders.length, 0);
        vm.stopPrank();

        // add Liquidity after as ALICE for both tokens
        vm.startPrank(alice);
        // add y
        tokens[y].mint(a);
        tokens[y].approve(address(pair), a);
        pair.addLiquidity(false, a,alice);
        assertEq(pair.balances(alice, address(tokens[y])), a);
        s = SmartPair.Side.REMOVE0_DEPOSIT1;
        orders = pair.orderBook(s);
        assertEq(orders.length, 0);
        //add x
        tokens[x].mint(a);
        tokens[x].approve(address(pair), a);
        pair.addLiquidity(true, a,alice);
        assertEq(pair.balances(alice, address(tokens[x])), 0);
        s = SmartPair.Side.DEPOSIT0_REMOVE1;
        orders = pair.orderBook(s);
        assertTrue(orders.length > 0);
        assertTrue(orders[0].investor == alice);
        assertEq(orders[0].amount, a);
        assertEq(orders[0].fulfilled, 0);
        SmartPair.Option op = SmartPair.Option.DEPOSIT;
        assertTrue(orders[0].option == op);
        vm.stopPrank();

        //place new order as JEFF
        vm.startPrank(jeff);
        tokens[y].mint(a);
        tokens[y].approve(address(pair), a);
        pair.addLiquidity(false, a,jeff);
        vm.stopPrank();

        //should be abl_token1e to deposit all

        uint256 jeffBalanceY = pair.balances(jeff, address(tokens[y]));
        uint256 aliceBalanceX = pair.balances(alice, address(tokens[x]));
        assertEq(aliceBalanceX, a);
        assertEq(jeffBalanceY, a);

        emit log_named_uint("X DEPOSITED BY ALICE: ", aliceBalanceX);
        emit log_named_uint("Y DEPOSITED BY JEFF: ", jeffBalanceY);
    }

    // add liquidity first using router
   /*  function test_router_add_liquidity_first(uint256 x, uint256 y, uint256 a) public {
        vm.assume(x != y && x < y);
        vm.assume(x < tokens.length && y < tokens.length);
        vm.assume(a < 200000e18 && a > 0);

        mockToken token0 = tokens[x];
        mockToken token1 = tokens[y];

        //mint tokens
        token0.mint(a);
        token0.approve(address(router), a);
        uint256 shares = router.addLiquidity(address(token0), address(token1), true, a, a);
        assertEq(shares,a);
        
    }

    function test_router_add_liquidity_second(uint256 x, uint256 y, uint256 a) public {
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

    function test_router_fulfill_liquidity_orders(uint256 x, uint256 y, uint256 a) public {
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

 */

    function test_router_swap_single(uint256 a) public {
        mockToken token0=tokens[2];
        mockToken token1=tokens[5];
        uint256 amount = 500000e18;
        vm.assume(a < amount && a > 0);
        test_fulfill_liquidity_orders(a);

        //jeff performs a swap

        vm.startPrank(jeff);
        token0.mint(a);
        token0.approve(address(router), a);
        uint256 amountOutAprox = router.getAmountOut(address(token0), address(token1), a);
        assertEq(amountOutAprox, router.swapSingle(address(token0), address(token1), a, 0, block.timestamp));
    }

    

   /*  function test_time_multishop() public {
        mockToken token0 = tokens[5];
        mockToken token1 = tokens[8];
        uint256 time = block.timestamp;
        vm.roll(100);
        token0.mint(100);
        token0.approve(address(router), 100);
        uint256 amountOutAprox = router.getAmountOut(address(token0), address(token1), 100);
        vm.expectRevert("TIME_EXPIRED");
        router.swapSingle(address(token0), address(token1), 100, 0, time);
        
    } */
}
