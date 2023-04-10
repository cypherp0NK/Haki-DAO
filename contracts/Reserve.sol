//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reserve {
    address public HAKI;
    constructor(address _haki){
        HAKI = _haki;
    }

    function approveContract(address _HakiDAO, uint _amount) external {
        IERC20(HAKI).approve(_HakiDAO, _amount);
    }

    function getBalance() external view returns(uint256){
        return IERC20(HAKI).balanceOf(address(this));
    }
    function sendTokens(address _destination, uint _amount) external {
        IERC20(HAKI).transfer(_destination, _amount);
    }
}