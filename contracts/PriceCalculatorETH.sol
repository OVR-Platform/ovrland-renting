// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IUniswapV3PoolState.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPriceCalculator.sol";

contract PriceCalculatorETH is OwnableUpgradeable {
  using SafeMath for uint256;

  IUniswapV3PoolState public constant OVRPool =
    IUniswapV3PoolState(0x34C9Bd5855EE203a08644Df68B9da0cc450F81A5); //OVR POOL MATIC

  AggregatorV3Interface private constant maticPriceFeed =
    AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // MATIC/USD

  /* ========== Value Calculation ========== */

  function priceOfMATIC() public view returns (uint256) {
    (, int256 price, , , ) = maticPriceFeed.latestRoundData();
    return uint256(price).mul(1e10);
  }

  function valueOfAsset(uint256 amount)
    public
    view
    returns (uint256 valueInUSD)
  {
    (uint256 sqrtPriceX96, , , , , , ) = OVRPool.slot0();

    uint256 priceInMatic = ((sqrtPriceX96**2).mul(1e18)).div(2**192);

    uint256 priceInUSD = priceInMatic.mul(priceOfMATIC()).div(1e18);
    uint256 totalPrice = priceInUSD.mul(amount);

    return totalPrice;
  }
}
