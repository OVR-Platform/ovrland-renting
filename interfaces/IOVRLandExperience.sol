// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "../interfaces/IOVRERC721.sol";

interface IOVRLandExperience {
  function startTokenRenting(
    IOVRERC721 _address,
    uint256 _nftId,
    address _renter,
    uint256 _startDate,
    uint256 _months,
    string memory _uri
  ) external returns (bool);

  function isOVRLandRented(uint256 _nftId) external returns (bool);

  function isTokenRented(IOVRERC721 _address, uint256 _landId)
    external
    view
    returns (bool _onSelling);

  function updateExperience(uint256 _nftId, string memory _uri) external;

  function getExperienceInfo(IOVRERC721 _contractAddress, uint256 _nftId)
    external
    view
    returns (
      string memory experience,
      uint256 date,
      uint256 monthsRenting,
      address currentRenter
    );
}
