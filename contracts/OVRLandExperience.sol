//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IOVRERC721.sol";
import "../interfaces/IOVRLandRenting.sol";

contract OVRLandExperience is UUPSUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    IOVRERC721 public OVRLand;
    IOVRERC721 public OVRLandContainer;
    IOVRLandRenting public OVRLandRenting;

    // Owner Experience
    mapping(IOVRERC721 => mapping(uint256 => string)) public experiences;

    // Renter Experience
    mapping(IOVRERC721 => mapping(uint256 => string)) public rentingExperiences;
    mapping(IOVRERC721 => mapping(uint256 => uint256)) public rentingDates;
    mapping(IOVRERC721 => mapping(uint256 => uint256)) public months;
    mapping(IOVRERC721 => mapping(uint256 => address)) public renter;

    // prettier-ignore
    function initialize(IOVRERC721 _OVRLandAddress, IOVRLandRenting _ovrLandRentingAddress, IOVRERC721 _OVRLandContainer)public initializer  {
        OVRLand = _OVRLandAddress;
        OVRLandRenting = _ovrLandRentingAddress;
        OVRLandContainer = _OVRLandContainer;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // prettier-ignore
    event ExperienceUpdated(IOVRERC721 indexed contractAddress, uint256 indexed nftId, address indexed sender, uint256 timestamp, bool renting, string uri);
    // prettier-ignore
    event TokenRented(IOVRERC721 indexed contractAddress, uint256 indexed nftId, address indexed renter, uint256 startDate, uint256 months, string uri);

    modifier isAllowedContractAddress(IOVRERC721 _contractAddress) {
        // prettier-ignore
        require(_contractAddress == OVRLand || _contractAddress == OVRLandContainer, "address not allowed");
        _;
    }

    function addAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function removeAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /* ========== EXPERIENCES ========== */

    //a function view that will return rentingExperiences, rentingDates, months and renter
    function getExperienceInfo(IOVRERC721 _contractAddress, uint256 _nftId)
        public
        view
        returns (
            string memory experience,
            uint256 date,
            uint256 monthsRenting,
            address currentRenter
        )
    {
        return (
            rentingExperiences[_contractAddress][_nftId],
            rentingDates[_contractAddress][_nftId],
            months[_contractAddress][_nftId],
            renter[_contractAddress][_nftId]
        );
    }

    /**
     * @notice Check if OVRLand is rented, rentingDates == 0 not rented
     * @param _contractAddress ERC721 contract address
     * @param _nftId NFT ID
     * @return bool Rented
     */
    function isTokenRented(IOVRERC721 _contractAddress, uint256 _nftId)
        public
        view
        isAllowedContractAddress(_contractAddress)
        returns (bool)
    {
        if (rentingDates[_contractAddress][_nftId] == 0) {
            return false;
        } else {
            if (
                _now() >= rentingDates[_contractAddress][_nftId] &&
                _now() <=
                rentingDates[_contractAddress][_nftId].add(
                    months[_contractAddress][_nftId].mul(30 days)
                )
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    /**
     * @notice Get current OVRLand Experience URI
     * @param _contractAddress ERC721 contract address
     * @param _nftId OVRLand NFT ID
     * @return string URI
     */
    function experienceURI(IOVRERC721 _contractAddress, uint256 _nftId)
        public
        view
        isAllowedContractAddress(_contractAddress)
        returns (string memory)
    {
        if (isTokenRented(_contractAddress, _nftId)) {
            return rentingExperiences[_contractAddress][_nftId];
        } else {
            return experiences[_contractAddress][_nftId];
        }
    }

    /**
     * @notice Get current OVRLand Renting Expiration
     * @param _contractAddress ERC721 contract address
     * @param _nftId OVRLand NFT ID
     * @return expiration timestamp
     */
    function rentingExpiration(IOVRERC721 _contractAddress, uint256 _nftId)
        public
        view
        isAllowedContractAddress(_contractAddress)
        returns (uint256)
    {
        uint256 expiration;
        if (isTokenRented(_contractAddress, _nftId)) {
            return
                rentingDates[_contractAddress][_nftId].add(
                    months[_contractAddress][_nftId].mul(30 days)
                );
        } else return expiration;
    }

    /**
     * @notice Update current OVRLand Experience URI
     * @param _contractAddress ERC721 contract address
     * @param _nftId OVRLand NFT ID
     * @param _uri OVRLand Experience URI
     */
    function updateExperience(
        IOVRERC721 _contractAddress,
        uint256 _nftId,
        string memory _uri
    ) public isAllowedContractAddress(_contractAddress) {
        if (isTokenRented(_contractAddress, _nftId)) {
            // prettier-ignore
            require(_msgSender() == renter[_contractAddress][_nftId], "Not the renter");
            rentingExperiences[_contractAddress][_nftId] = _uri;
            // prettier-ignore
            emit ExperienceUpdated(_contractAddress, _nftId, _msgSender(), _now(), true, _uri);
        } else {
            // prettier-ignore
            require(_msgSender() == OVRLand.ownerOf(_nftId) || _msgSender() == address(OVRLandContainer), "Not the owner");
            experiences[_contractAddress][_nftId] = _uri;
            // prettier-ignore
            emit ExperienceUpdated(_contractAddress, _nftId, _msgSender(), _now(), false, _uri);
        }
    }

    /**
     * @notice Update current OVRLand Experience URI only from Admin
     * @param _nftId OVRLand NFT ID
     * @param _uri OVRLand Experience URI
     */
    function adminUpdateExperience(
        IOVRERC721 _address,
        uint256 _nftId,
        string memory _uri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) isAllowedContractAddress(_address) {
        experiences[_address][_nftId] = _uri;
        // prettier-ignore
        emit ExperienceUpdated(_address, _nftId, _msgSender(), _now(), false, _uri);
    }

    /**
     * @notice Callable by OVRLandRenting
     * @param _contractAddress ERC721 contract address
     * @param _nftId OVRLand NFT ID
     * @param _renter renter
     * @param _startDate renting start date
     * @param _months renting duration
     * @param _uri experience uri
     * @return bool is started
     */
    function startTokenRenting(
        IOVRERC721 _contractAddress,
        uint256 _nftId,
        address _renter,
        uint256 _startDate,
        uint256 _months,
        string memory _uri
    ) public isAllowedContractAddress(_contractAddress) returns (bool) {
        require(_msgSender() == address(OVRLandRenting), "Non valid execution");
        require(!isTokenRented(_contractAddress, _nftId), "OVRLand rented");

        rentingDates[_contractAddress][_nftId] = _startDate;
        months[_contractAddress][_nftId] = _months;
        renter[_contractAddress][_nftId] = _renter;
        rentingExperiences[_contractAddress][_nftId] = _uri;
        // prettier-ignore
        emit TokenRented(_contractAddress, _nftId, _renter, _startDate, _months, _uri);
        return true;
    }

    function setContainerAddress(IOVRERC721 _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        OVRLandContainer = _address;
    }

    function setRentingAddress(IOVRLandRenting _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        OVRLandRenting = _address;
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
