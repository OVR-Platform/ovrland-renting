// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "hardhat/console.sol";
// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// Interfaces
import "../interfaces/IMarketplace.sol";
import "../interfaces/IExperience.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract OVRLandContainer is
  UUPSUpgradeable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721URIStorageUpgradeable,
  ERC721BurnableUpgradeable,
  AccessControlUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using SafeMathUpgradeable for uint256;

  CountersUpgradeable.Counter private _tokenIdCounter;

  IERC721 public OVRLand;
  IMarketplace public marketplace;
  IExperience public experience;

  function initialize(IERC721 _OVRLand, uint256 _maxLandsPerContainer)
    external
    initializer
  {
    __AccessControl_init();
    __ERC721Enumerable_init();
    __ERC721URIStorage_init();
    __ERC721Burnable_init();
    __ERC721_init("OVRLand Container", "OVRLandC");

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    maxLandsPerContainer = _maxLandsPerContainer;
    OVRLand = _OVRLand;
  }

  // prettier-ignore
  event ContainerCreated(uint256 indexed containerId, address indexed creator, uint256[] lands, uint256 timestamp);
  // prettier-ignore
  event ContainerDeleted(uint256 indexed containerId, address indexed owner, uint256 timestamp);

  // OVRLandContainer Token ID => OVRLand index => OVRLand Token ID
  mapping(uint256 => mapping(uint256 => uint256)) public containerToLands;
  // OVRLand Token ID =>  OVRLandContainer Token ID
  mapping(uint256 => uint256) public landToContainer;
  // OVRLandContainer Token ID => numberOfLands + 1 (if containerLandsCount[256] return 4, max indexLands of container is 3 'cause it starts from 0)
  mapping(uint256 => uint256) public containerLandsCount;
  // OVRLand Token ID => OVRLand index inside container
  mapping(uint256 => uint256) public landIndex;
  // OVRLandContainer Token ID => name
  mapping(uint256 => string) public containerNames;

  uint256 public maxLandsPerContainer;

  /**
   * @notice verify that the caller is the owner of the container
   * @param _containerId The id of container
   */
  modifier isContainerOwner(uint256 _containerId) {
    require(ownerOf(_containerId) == _msgSender(), "Caller is not the owner");
    _;
  }

  /**
   * @notice Verify that the lands sent aren't rented or on sale
   * @param _landIds Array of OVRLand ids
   */
  function landsFree(uint256[] memory _landIds) internal view returns (bool) {
    uint256 length = _landIds.length;

    bool marketplaceExist = address(marketplace) != address(0);
    bool experienceExist = address(experience) != address(0);

    if (marketplaceExist == false && experienceExist == false) {
      return true;
    }

    for (uint256 i = 0; i < length; i++) {
      if (marketplaceExist) {
        // prettier-ignore
        require(marketplace.landIsOnSelling(_landIds[i]) == false, "One or more lands are on sale");
      }

      if (experienceExist) {
        // prettier-ignore
        require(experience.isTokenRented(OVRLand, _landIds[i]) == false, "One or more lands are rented");
      }
    }
    return true;
  }

  /**
   * @notice Verify that the container not rentend or on sale
   * @param _containerId The container id
   */
  function containerFree(uint256 _containerId) internal view returns (bool) {
    bool marketplaceExist = address(marketplace) != address(0);
    bool experienceExist = address(experience) != address(0);

    if (marketplaceExist == false && experienceExist == false) {
      return true;
    }

    if (marketplaceExist) {
      // prettier-ignore
      require(marketplace.containerIsOnSelling(_containerId) == false, "Container is on sale");
    }

    if (experienceExist) {
      // prettier-ignore
      require(experience.isTokenRented(IERC721(address(this)), _containerId) == false, "Container is rented");
    }

    return true;
  }

  /**
   * @param _landId OVRLand token id
   * @return owner Given a landId return the owner
   */
  function ownerOfChild(uint256 _landId) public view returns (address owner) {
    uint256 containerOfChild = landToContainer[_landId];
    address ownerAddressOfChild = ownerOf(containerOfChild);

    // prettier-ignore
    require(ownerAddressOfChild != address(0), "Query for a non existing container");
    return ownerAddressOfChild;
  }

  function containerName(uint256 _containerId)
    public
    view
    returns (string memory name)
  {
    // prettier-ignore
    require(_exists(_containerId), "ERC721: query for nonexistent container");
    return containerNames[_containerId];
  }

  /**
   * @param _containerId OVRLandContainer token id
   * @return lands Given a containerId return the lands inside
   */
  function childsOfParent(uint256 _containerId)
    public
    view
    returns (uint256[] memory lands)
  {
    // prettier-ignore
    require(_exists(_containerId), "ERC721: query for nonexistent container");

    uint256 count = containerLandsCount[_containerId];
    uint256[] memory childs = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      childs[i] = containerToLands[_containerId][i];
    }

    return childs;
  }

  /**
   * @notice Function to set marketplace address, can be called only by an admin
   * @param _marketplace Marketplace address
   */
  function setMarketplaceAddress(IMarketplace _marketplace)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    marketplace = _marketplace;
  }

  /**
   * @notice function to set renting address, can be called only by an admin
   * @param _experience Experience address
   */
  function setExperienceAddress(IExperience _experience)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    experience = _experience;
  }

  /**
   * @notice Function to create a container, it needs an array of lands
   * @param _landIds Array of OVRLand token ids
   * @param _name Container name
   */
  function createContainer(uint256[] memory _landIds, string memory _name)
    public
  {
    require(landsFree(_landIds), "One or more lands are busy");
    uint256 length = _landIds.length;
    require(
      length > 1 && length <= maxLandsPerContainer,
      "Invalid container size"
    );
    uint256 tokenId = _tokenIdCounter.current();

    for (uint256 i = 0; i < length; i++) {
      // It checks if token exists and is owner

      OVRLand.transferFrom(_msgSender(), address(this), _landIds[i]);
      landToContainer[_landIds[i]] = tokenId;
      landIndex[_landIds[i]] = i;
      containerToLands[tokenId][i] = _landIds[i];
    }

    containerLandsCount[tokenId] = length;
    containerNames[tokenId] = _name;

    _tokenIdCounter.increment();
    _safeMint(_msgSender(), tokenId);
    emit ContainerCreated(tokenId, _msgSender(), _landIds, block.timestamp);
  }

  /**
   * @notice function to destroy a container
   * @param _containerId Container id
   */
  function deleteContainer(uint256 _containerId)
    public
    isContainerOwner(_containerId)
  {
    require(containerFree(_containerId), "Container is busy");
    // prettier-ignore
    require(_exists(_containerId), "ERC721: query for nonexistent container");
    uint256 numberOfLands = containerLandsCount[_containerId];

    // the container doesn't exist anymore
    delete containerLandsCount[_containerId];
    for (uint256 i = 0; i < numberOfLands; i++) {
      delete landToContainer[containerToLands[_containerId][i]];
      delete landIndex[containerToLands[_containerId][i]];
      delete containerNames[_containerId];

      OVRLand.transferFrom(
        address(this),
        _msgSender(),
        containerToLands[_containerId][i]
      );

      delete containerToLands[_containerId][i];
    }

    _burn(_containerId);
    emit ContainerDeleted(_containerId, _msgSender(), block.timestamp);
  }

  /**
   * @notice Function to update a land experience if inside a container
   * @param _landId OVRLand token id
   */
  function updateExperienceLand(uint256 _landId, string memory _uri) public {
    require(_msgSender() == ownerOfChild(_landId), "Not owner");
    experience.updateExperience(_landId, _uri);
  }

  /**
   * @notice function to destroy a container
   */
  function deleteContainerByAdmin(uint256 _containerId)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_exists(_containerId), "ERC721: query for nonexistent container");
    address containerOwner = ownerOf(_containerId);
    uint256 numberOfLands = containerLandsCount[_containerId];
    // the container doesn't exist anymore
    delete containerLandsCount[_containerId];
    for (uint256 i = 0; i < numberOfLands; i++) {
      delete landToContainer[containerToLands[_containerId][i]];
      delete landIndex[containerToLands[_containerId][i]];

      OVRLand.transferFrom(
        address(this),
        containerOwner,
        containerToLands[_containerId][i]
      );
      delete containerToLands[_containerId][i];
    }

    _burn(_containerId);
    emit ContainerDeleted(_containerId, _msgSender(), block.timestamp);
  }

  function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function removeAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  /**
   * @dev Function to set the OVRLandContainer IPFS uri.
   * @param _tokenId uint256 ID of the OVRLandContainer
   * @param _uri string of the OVRLandContainer IPFS uri
   */
  function setOVRLandContainerURI(uint256 _tokenId, string memory _uri)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setTokenURI(_tokenId, _uri);
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      AccessControlUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}
