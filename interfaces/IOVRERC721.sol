// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOVRERC721 is IERC721 {
  function mint(address _user, uint256 _tokenId) external returns (bool);

  function safeMint(
    address _user,
    uint256 _tokenId,
    string memory _uri
  ) external returns (bool);

  function tokenURI(uint256 tokenId) external returns (string memory);

  function setOVRLandURI(uint256 OVRLandID, string memory uri) external;
}
