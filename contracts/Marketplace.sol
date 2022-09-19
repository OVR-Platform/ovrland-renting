//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract Marketplace is
  UUPSUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  /* ========== STATE VARIABLES ========== */

  IERC20Upgradeable public token;
  address public feeReciver;
  uint256 public feePerc;
  uint256 public minOffer;
  IERC721Upgradeable public land;
  IERC721Upgradeable public container;
  address public treasury;

  mapping(IERC721Upgradeable => mapping(uint256 => Offer)) public bestOffers;
  mapping(IERC721Upgradeable => mapping(uint256 => OnSell)) public selling;
  mapping(IERC721Upgradeable => mapping(uint256 => bool)) public nftOnSelling;
  mapping(IERC721Upgradeable => uint256) public customFees;

  /* ========== INITIALIZER ========== */

  /**
   * @dev Called on deployment by deployProxy
   *
   * @param _tokenAddress The ERC20 token address
   * @param _feeX100 Percentage fee
   * @param _feeReciver Who receive fees
   */
  function initialize(
    address _tokenAddress,
    IERC721Upgradeable _land,
    IERC721Upgradeable _container,
    uint256 _feeX100,
    address _feeReciver,
    uint256 _minOffer,
    address _treasury
  ) external initializer {
    token = IERC20Upgradeable(_tokenAddress);
    __AccessControl_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    land = _land;
    container = _container;
    feePerc = _feeX100; // 5% -> 500
    feeReciver = _feeReciver;
    minOffer = _minOffer;
    treasury = _treasury;
  }

  function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function removeAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  /* ========== STRUCTS ========== */

  /**
   * @param from - _msgSender()
   * @param ERC721 - nft address
   * @param nftId - NFT id
   * @param value - offer value in OVR token
   * @param timestamp - when offer was placed
   * @param fee - fee in OVR to pay to us for sell
   */
  struct Offer {
    address from;
    IERC721Upgradeable ERC721;
    uint256 nftId;
    uint256 value;
    uint256 fee;
    uint256 timestamp;
  }

  /**
   * @param from - _msgSender()
   * @param ERC721 - nft address
   * @param nftId - NFT id
   * @param value - offer value in OVR token
   * @param timestamp - when offer was placed
   * @param fee - fee in OVR to pay to us for sell
   */
  struct OnSell {
    address from;
    IERC721Upgradeable ERC721;
    uint256 nftId;
    uint256 value;
    uint256 fee;
    uint256 timestamp;
  }

  /* ========== EVENTS ========== */

  event OfferPlaced(
    address indexed sender,
    uint256 indexed nftId,
    uint256 value,
    uint256 timestamp
  );
  event OfferCancelled(
    uint256 indexed nftId,
    address indexed sender,
    address indexed to,
    uint256 timestamp
  );
  event OfferAccepted(
    address indexed owner,
    uint256 indexed nftId,
    address indexed to,
    uint256 value,
    uint256 timestamp
  );
  event Sold(
    address indexed seller,
    uint256 indexed nftId,
    uint256 value,
    uint256 timestamp
  );
  event SellCancelled(
    uint256 indexed nftId,
    address indexed sender,
    uint256 timestamp
  );
  event Bought(
    uint256 indexed nftId,
    uint256 value,
    address indexed sender,
    uint256 timestamp
  );
  event PriceNftChanged(
    uint256 indexed nftId,
    uint256 newPrice,
    uint256 timestamp
  );

  /* ========== MODIFIERS ========== */

  modifier isNftOwner(IERC721Upgradeable _address, uint256 _nftId) {
    require(
      _address.ownerOf(_nftId) == _msgSender(),
      "Not the owner of this NFT"
    );
    _;
  }

  modifier isNftOwnerOrOfferer(IERC721Upgradeable _address, uint256 _nftId) {
    require(
      _msgSender() == bestOffers[_address][_nftId].from ||
        _address.ownerOf(_nftId) == _msgSender(),
      "Not a offeror or nft owner"
    );
    _;
  }

  modifier onSelling(IERC721Upgradeable _address, uint256 _nftId) {
    require(
      selling[_address][_nftId].from == _address.ownerOf(_nftId),
      "Not for sale"
    );
    _;
  }

  /**
   * @dev the given nft is not OVRLand or OVRContainer
   */
  modifier notLandOrContainer(IERC721Upgradeable _address) {
    require(
      _address != land && _address != container,
      "You can't sell this NFT here"
    );
    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @dev Get the last buy offer
   * @param _address address of token
   * @param _nftId Nft token id
   *
   * @return _offer Offer
   */
  function lastOffer(IERC721Upgradeable _address, uint256 _nftId)
    public
    view
    returns (Offer memory _offer)
  {
    return bestOffers[_address][_nftId];
  }

  /**
   * @dev Get the last sell offer
   * @param _address address of token
   * @param _nftId token id
   *
   * @return _sell OnSell
   */
  function sellView(IERC721Upgradeable _address, uint256 _nftId)
    public
    view
    onSelling(_address, _nftId)
    returns (OnSell memory _sell)
  {
    return selling[_address][_nftId];
  }

  /**
   * @dev Check if Nft is on selling
   * @param _address address of token
   * @param _nftId token id
   *
   * @return _onSelling bool
   */
  function nftIsOnSelling(IERC721Upgradeable _address, uint256 _nftId)
    public
    view
    returns (bool _onSelling)
  {
    return nftOnSelling[_address][_nftId];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @dev Update fee receiver address
   * @param _feeAddr new address
   */
  function setFeeAddr(address _feeAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReciver = _feeAddr;
  }

  /**
   * @dev To place an offer for a specified nft by everyone
   * @notice if a bid is outbid, the bidder of the outbid bid will get back the
   * tokens thanks to the moneyBack() function;
   * the bidder will send tokens to the treasury (this to avoid fake offers)
   * @param _nftId Nft tokenId
   * @param _address address of token
   * @param _value offer amount
   */
  function placeOffer(
    IERC721Upgradeable _address,
    uint256 _nftId,
    uint256 _value
  ) public whenNotPaused notLandOrContainer(_address) {
    require(_value > bestOffers[_address][_nftId].value, "Offer is too low!");
    require(_value > minOffer, "Offer is too low!");
    uint256 currentTimestamp = _now();
    uint256 fees;
    moneyBack(_address, _nftId);

    if (customFees[_address] != 0) {
      fees = _value.mul(customFees[_address]).div(1e4);
    } else {
      fees = _value.mul(feePerc).div(1e4);
    }

    bestOffers[_address][_nftId].fee = fees;
    bestOffers[_address][_nftId].nftId = _nftId;
    bestOffers[_address][_nftId].ERC721 = _address;
    bestOffers[_address][_nftId].from = _msgSender();
    bestOffers[_address][_nftId].value = _value;
    bestOffers[_address][_nftId].timestamp = currentTimestamp;

    uint256 totalToPay = fees.add(_value);

    require(
      token.transferFrom(_msgSender(), treasury, totalToPay),
      "Insufficient allowance"
    );
    emit OfferPlaced(_msgSender(), _nftId, _value, currentTimestamp);
  }

  /**
   * @dev To accept a sell offer, only the owner of the NFT can accept
   * @param _address address of token
   * @param _nftId nft tokenId
   */
  function acceptOffer(IERC721Upgradeable _address, uint256 _nftId)
    public
    isNftOwner(_address, _nftId)
    whenNotPaused
    nonReentrant
  {
    address to = bestOffers[_address][_nftId].from;
    require(bestOffers[_address][_nftId].from != address(0), "No offers");
    require(
      token.transferFrom(
        treasury,
        _msgSender(),
        bestOffers[_address][_nftId].value
      ),
      "Insufficient contract balance"
    );
    require(
      token.transferFrom(
        treasury,
        feeReciver,
        bestOffers[_address][_nftId].fee
      ),
      "Insufficient contract balance"
    );

    uint256 currentTimestamp = _now();

    _address.transferFrom(
      _msgSender(),
      bestOffers[_address][_nftId].from,
      _nftId
    );

    nftOnSelling[_address][_nftId] = false;
    uint256 value = bestOffers[_address][_nftId].value;
    delete bestOffers[_address][_nftId];
    delete selling[_address][_nftId];

    emit OfferAccepted(_msgSender(), _nftId, to, value, currentTimestamp);
  }

  /**
   * @dev This function can be called by the owner of the nft to sell it
   * @param _address address of token
   * @param _nftId nft tokenId
   * @param _value sell offer amount
   */
  function sell(
    IERC721Upgradeable _address,
    uint256 _nftId,
    uint256 _value
  )
    public
    isNftOwner(_address, _nftId)
    notLandOrContainer(_address)
    whenNotPaused
  {
    /**
     * Give the owner the ability to overwrite the sale if
     * the old owner did not cancel the previous sale.
     **/
    require(
      nftOnSelling[_address][_nftId] == false ||
        selling[_address][_nftId].from != _address.ownerOf(_nftId),
      "Already on selling"
    );
    uint256 fees;
    if (customFees[_address] != 0) {
      fees = _value.mul(customFees[_address]).div(1e4);
    } else {
      fees = _value.mul(feePerc).div(1e4);
    }
    uint256 currentTimestamp = _now();
    selling[_address][_nftId].fee = fees;
    selling[_address][_nftId].nftId = _nftId;
    selling[_address][_nftId].from = _msgSender();
    selling[_address][_nftId].value = _value;
    selling[_address][_nftId].timestamp = currentTimestamp;
    selling[_address][_nftId].ERC721 = _address;
    nftOnSelling[_address][_nftId] = true;
    emit Sold(_msgSender(), _nftId, _value, currentTimestamp);
  }

  /**
   * @notice function to cancel an offer by the owner of the nft or the offeror
   * @dev it will give back the money to the offeror
   * @param _address address of token
   * @param _nftId Nft tokenId
   */
  function cancelOffer(IERC721Upgradeable _address, uint256 _nftId)
    public
    isNftOwnerOrOfferer(_address, _nftId)
  {
    uint256 currentTimestamp = _now();
    address to = bestOffers[_address][_nftId].from;
    moneyBack(_address, _nftId);
    delete bestOffers[_address][_nftId];
    emit OfferCancelled(_nftId, _msgSender(), to, currentTimestamp);
  }

  /**
   * @dev Change Nft price on selling, can be called only by the owner
   * @param _address address of token
   * @param _nftId Nft tokenId
   * @param _price amount
   */
  function updatePriceNft(
    IERC721Upgradeable _address,
    uint256 _nftId,
    uint256 _price
  ) public isNftOwner(_address, _nftId) {
    require(nftOnSelling[_address][_nftId] == true, "NFT not on selling");
    uint256 fees;
    if (customFees[_address] != 0) {
      fees = _price.mul(customFees[_address]).div(1e4);
    } else {
      fees = _price.mul(feePerc).div(1e4);
    }
    uint256 currentTimestamp = _now();
    selling[_address][_nftId].value = _price;
    selling[_address][_nftId].fee = fees;
    emit PriceNftChanged(_nftId, _price, currentTimestamp);
  }

  /**
   * @dev Delete Nft on selling, can be called only by the owner
   * @param _address address of token
   * @param _nftId Nft tokenId
   */
  function cancelSell(IERC721Upgradeable _address, uint256 _nftId)
    public
    isNftOwner(_address, _nftId)
  {
    uint256 currentTimestamp = _now();
    nftOnSelling[_address][_nftId] = false;
    delete selling[_address][_nftId];
    emit SellCancelled(_nftId, _msgSender(), currentTimestamp);
  }

  /**
   * @notice This function can be called by everyone to buy Nft which was previously put up for sale by the owner
   * @dev if the current owner of the nft is not the same person who put the nft up for sale, the nft cannot be bought
   * @param _address address of token
   * @param _nftId Nft tokenId
   */
  function buy(IERC721Upgradeable _address, uint256 _nftId)
    public
    whenNotPaused
    nonReentrant
    onSelling(_address, _nftId)
  {
    uint256 minBalance = selling[_address][_nftId].value.add(
      selling[_address][_nftId].fee
    );
    require(token.balanceOf(_msgSender()) >= minBalance, "Not enough balance");
    require(
      token.transferFrom(
        _msgSender(),
        selling[_address][_nftId].from,
        selling[_address][_nftId].value
      ),
      "Insufficient allowance"
    );
    require(
      token.transferFrom(
        _msgSender(),
        feeReciver,
        selling[_address][_nftId].fee
      ),
      "Insufficient allowance"
    );
    _address.transferFrom(selling[_address][_nftId].from, _msgSender(), _nftId);
    uint256 currentTimestamp = _now();
    uint256 value = selling[_address][_nftId].value;
    delete selling[_address][_nftId];
    nftOnSelling[_address][_nftId] = false;
    emit Bought(_nftId, value, _msgSender(), currentTimestamp);
  }

  function changeBaseFee(uint256 _feeX100) public onlyRole(DEFAULT_ADMIN_ROLE) {
    feePerc = _feeX100;
  }

  /**
   * @dev custom fees for a specified collection
   */
  function changeFeeForNFT(uint256 _feeX100, IERC721Upgradeable _address)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    customFees[_address] = _feeX100;
  }

  function changeMinOffer(uint256 _minOffer)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    minOffer = _minOffer;
  }

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
    _unpause();
  }

  /**
   * @dev withdraw everytoken deposited to the contract
   */

  function withdraw(IERC20Upgradeable _token)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _token.transfer(_msgSender(), _token.balanceOf(address(this)));
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * @dev This function will give back money to bidders when they cancel their offer, or their offer is outbid
   * @param _address address of token
   * @param _nftId Nft tokenId
   */
  function moneyBack(IERC721Upgradeable _address, uint256 _nftId)
    internal
    nonReentrant
  {
    if (bestOffers[_address][_nftId].from != address(0)) {
      uint256 oldFee = bestOffers[_address][_nftId].fee;
      address from = bestOffers[_address][_nftId].from;
      uint256 paid = bestOffers[_address][_nftId].value;

      uint256 totalToReturn = paid.add(oldFee);
      bestOffers[_address][_nftId].from = address(0);
      require(
        token.transferFrom(treasury, from, totalToReturn),
        "Insufficient contract balance"
      );
    }
  }

  function _authorizeUpgrade(address)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  /**
   * @return Returns current timestamp.
   */
  function _now() internal view returns (uint256) {
    // Note that the timestamp can have a 900-second error:
    // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
    // return now; // solium-disable-line security/no-block-members
    return block.timestamp;
  }
}
