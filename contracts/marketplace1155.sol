// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//libraries
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

//interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Marketplace1155 is
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  mapping(IERC1155Upgradeable => bool) public collectionAllowed;
  mapping(IERC1155Upgradeable => mapping(address => Sell)) public onSelling;
  mapping(IERC1155Upgradeable => uint256) public customFeesX100;

  IERC20Upgradeable public ovr;
  Sell[] public sellArray;

  function initialize(IERC20Upgradeable _ovr) external initializer {
    ovr = _ovr;
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  struct Sell {
    IERC1155Upgradeable collectionAddress;
    uint256 tokenId;
    uint256 amount;
    uint256 price;
    uint256 fees;
    address owner;
  }

  event sold(
    IERC1155Upgradeable indexed collectionAddress,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 price,
    uint256 fees,
    address indexed owner
  );

  function addCollection(IERC1155Upgradeable _collection) external {
    require(!collectionAllowed[_collection], "Collection already added");
    collectionAllowed[_collection] = true;
  }

  function removeCollectio(IERC1155Upgradeable _collection) external {
    require(collectionAllowed[_collection], "Collection not listed");
    collectionAllowed[_collection] = false;
  }

  function buy(
    address _owner,
    IERC1155Upgradeable _collection,
    uint256 _tokenId
  ) public nonReentrant {
    require(onSelling[_collection][_owner].price != 0, "NFTs not on selling");
    require(
      _collection.balanceOf(_owner, _tokenId) >=
        onSelling[_collection][_owner].amount,
      "Not for selling"
    );
    require(
      ovr.transferFrom(
        _msgSender(),
        address(this),
        onSelling[_collection][_owner].price
      ),
      "Insufficient allowance"
    );
    _collection.safeTransferFrom(
      _owner,
      _msgSender(),
      _tokenId,
      onSelling[_collection][_owner].amount,
      "0x0"
    );
  }

  function sell(
    IERC1155Upgradeable _collection,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _price
  ) public nonReentrant {
    require(
      onSelling[_collection][_msgSender()].price == 0,
      "NFTs already on selling"
    );
    require(_amount > 0, "Amount must be > 0");
    require(_price > 0, "Price must be > 0");
    uint256 fee = (_price * customFeesX100[_collection]) / 1e4;

    onSelling[_collection][_msgSender()] = Sell(
      _collection,
      _tokenId,
      _amount,
      _price - fee,
      fee,
      _msgSender()
    );
    emit sold(_collection, _tokenId, _amount, _price, fee, _msgSender());
  }

  function _authorizeUpgrade(address)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}
