//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 
interface IWeth{
  function deposit() external payable;
}

interface IUniswapV2Factory{
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02{
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }
interface ILaunchpad{
  function createLiveLiquidity() external;
}

interface ILaunchpadFactory{
    function createLaunchpad(address _token, uint _softCap, uint _hardCap, uint _presaleRate, uint _startTime, uint _endTime, uint _minimumBuy, uint _maximumBuy) external returns (address);
}

contract Launchpad is ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint public PresaleRate;
    uint public StartTime;
    uint public EndTime;
    uint public MinimumBuy;
    uint public MaximumBuy;
    address public TokenForSale;
    uint public SoftCap;
    uint public HardCap;

    constructor(address _token, uint _softCap, uint _hardCap, uint _presaleRate, uint _startTime, uint _endTime, uint _minimumBuy, uint _maximumBuy){
        PresaleRate = _presaleRate;
        StartTime = _startTime;
        EndTime = _endTime;
        MinimumBuy = _minimumBuy;
        MaximumBuy = _maximumBuy;
        TokenForSale = _token;
        SoftCap = _softCap;
        HardCap = _hardCap;
    }
    function saleStatus() external view returns (bool){
        return block.timestamp >= StartTime;
    }
    function buyTokens() external payable nonReentrant{
        require(block.timestamp > StartTime, "Start time not yet reached");
        require(block.timestamp < EndTime, "Token sale ended");
        require(address(this).balance + msg.value < HardCap, "Cap reached");
        require(msg.value > MinimumBuy, "Value too low");
        require(msg.value < MaximumBuy, "Value too high");
        uint amtToSend = msg.value * PresaleRate;
        IERC20(TokenForSale).safeTransfer(msg.sender, amtToSend);
    }
    
    function createLiveLiquidity() external {
        require(block.timestamp > EndTime, "End time not yet reached");
        IUniswapV2Factory(0xF502B3d87311863bb0aC3CF3d2729A78438116Cf).createPair(TokenForSale, 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
        IERC20(TokenForSale).safeApprove(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25, IERC20(TokenForSale).balanceOf(address(this)));
        IUniswapV2Router02(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25).addLiquidityETH(TokenForSale, IERC20(TokenForSale).balanceOf(address(this)), IERC20(TokenForSale).balanceOf(address(this)), address(this).balance, address(this), block.timestamp);
    }
    
}
contract LaunchpadFactory{
  function createLaunchpad(address _token, uint _softCap, uint _hardCap, uint _presaleRate, uint _startTime, uint _endTime, uint _minimumBuy, uint _maximumBuy) external returns (address){
        address _launchpad = address(new Launchpad(_token, _softCap, _hardCap, _presaleRate, _startTime, _endTime, _minimumBuy, _maximumBuy));
        return _launchpad;
    }
}
