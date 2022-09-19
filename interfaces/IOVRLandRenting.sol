// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;
import "../interfaces/IOVRERC721.sol";

interface IOVRLandRenting {
  function activateNoRentFromHosting(
    IOVRERC721 _address,
    uint256 _nftId,
    uint256 _period
  ) external;
}
