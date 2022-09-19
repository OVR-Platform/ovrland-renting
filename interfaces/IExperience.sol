// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IExperience {
  function isTokenRented(IERC721 _address, uint256 _landId)
    external
    view
    returns (bool _onSelling);

  function updateExperience(uint256 _nftId, string memory _uri) external;

  function getExperienceInfo(IERC721 _contractAddress, uint256 _nftId)
    external
    view
    returns (
      string memory experience,
      uint256 date,
      uint256 monthsRenting,
      address currentRenter
    );
}
