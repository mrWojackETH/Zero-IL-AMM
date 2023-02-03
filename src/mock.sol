import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 500000000e18);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
