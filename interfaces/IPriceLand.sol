// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;
import "../interfaces/IOVRERC721.sol";

interface IPriceLand {
  function getPrice(IOVRERC721 _address, uint256 _landId)
    external
    view
    returns (uint256);
}
