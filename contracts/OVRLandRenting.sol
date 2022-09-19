//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOVRERC721.sol";
import "../interfaces/IOVRLandExperience.sol";
import "../interfaces/IPriceLand.sol";

contract OVRLandRenting is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    IERC20 public token;
    IOVRERC721 public OVRLand;
    IOVRLandExperience public OVRLandExperience;
    address public OVRLandHosting;
    IOVRERC721 public OVRContainer;
    IPriceLand public priceLand;
    bytes32 public constant BASE_PRICE_CHANGER =
        keccak256("BASE_PRICE_CHANGER");

    mapping(IOVRERC721 => mapping(uint256 => Offer)) public offers;
    mapping(IOVRERC721 => mapping(uint256 => uint256)) public noRentsEnd;
    // prettier-ignore
    mapping(IOVRERC721 => mapping(uint256 => NoRentParams)) public noRentsParams;
    uint256 public noRentPriceLand;
    uint256 public noRentPriceContainer;
    uint256 public noRentDuration;
    uint256 public basePriceLands;
    uint256 public basePriceContainers;

    uint256 public feePerc;
    address public feeReceiver;
    uint256 public floorPrice;

    /**
     * @param from offer created by
     * @param nftId OVRLand ID
     * @param valuePerMonth OVR tokens per month
     * @param months number of months
     * @param fee fee in OVR
     * @param timestamp creation timestamp
     * @param experienceUri experience uri
     */
    // prettier-ignore
    struct Offer {IOVRERC721 nft; address from; uint256 nftId; uint256 valuePerMonth; uint256 months; uint256 fee; uint256 timestamp; string experienceUri;}
    // prettier-ignore
    struct NoRentParams {uint256 pricePerMonth; uint8 minMonths; uint8 maxMonths;}

    /* ========== EVENTS ========== */

    // prettier-ignore
    event OfferPlaced( address indexed token, uint256 indexed nftId, address indexed sender, uint256 amountPerMonth, uint256 months, uint256 timestamp, uint256 fees);
    // prettier-ignore
    event Overbid( address indexed token, uint256 indexed nftId, address indexed sender, uint256 amountPerMonth, uint256 months, uint256 timestamp, uint256 fees);
    // prettier-ignore
    event OfferAccepted( address indexed token, uint256 indexed nftId, address indexed sender, address renter, uint256 amountPerMonth, uint256 months, uint256 timestamp);
    // prettier-ignore
    event NoRentActivated( address indexed token, uint256 indexed nftId, address indexed owner, uint256 timestamp, uint256 endDate, uint256 minPrice, uint8 minMonths, uint8 maxMonths);
    // prettier-ignore
    event NoRentDeactivated( address indexed token, uint256 indexed nftId, address indexed owner, uint256 timestamp);
    // prettier-ignore
    event OfferCanceled(address indexed nft, uint256 indexed nftId, address indexed sender, uint256 timestamp);
    /* ========== MODIFIERS ========== */

    modifier isOfferBetter(
        IOVRERC721 _address,
        uint256 _nftId,
        uint256 _amount
    ) {
        uint256 timestamp = _now();

        if (timestamp < offers[_address][_nftId].timestamp.add(1 days)) {
            require(
                offers[_address][_nftId].valuePerMonth < _amount,
                "Offer is too low"
            );
        } else if (timestamp < offers[_address][_nftId].timestamp.add(8 days)) {
            revert("An offer already won");
        }
        _;
    }

    modifier isAllowedAddress(IOVRERC721 _address) {
        require(
            _address == OVRLand || _address == OVRContainer,
            "address not allowed"
        );
        _;
    }

    modifier areValidNoRentParams(NoRentParams calldata _noRentParams) {
        require(_noRentParams.pricePerMonth > 0, "Price per month over 0");
        // prettier-ignore
        require(_noRentParams.minMonths > 0 && _noRentParams.minMonths < 13, "minMonths between 1 and 12 months");
        // prettier-ignore
        require(_noRentParams.maxMonths > 0 && _noRentParams.maxMonths < 13, "maxMonths between 1 and 12 months");
        // prettier-ignore
        require(_noRentParams.maxMonths >= _noRentParams.minMonths, "maxMonths should be greater then minMonths");

        _;
    }

    function initialize(
        address _tokenAddress,
        address _OVRLandAddress,
        address _OVRLandExperience,
        address _OVRLandHosting,
        address _feeReceiver,
        uint256 _noRentPriceLand,
        uint256 _noRentPriceContainer,
        IOVRERC721 _OVRContainer,
        uint256 _basePriceLands,
        uint256 _basePriceContainers
    ) public initializer {
        token = IERC20(_tokenAddress);
        OVRLand = IOVRERC721(_OVRLandAddress);
        OVRLandExperience = IOVRLandExperience(_OVRLandExperience);
        OVRLandHosting = _OVRLandHosting;
        OVRContainer = _OVRContainer;

        noRentPriceLand = _noRentPriceLand;
        noRentPriceContainer = _noRentPriceContainer;
        noRentDuration = 90 days; // 3 months
        basePriceLands = _basePriceLands;
        basePriceContainers = _basePriceContainers;

        feePerc = 500; //5%
        feeReceiver = _feeReceiver;

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BASE_PRICE_CHANGER, _msgSender());
    }

    function addAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function removeAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function setBasePriceChanger(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(BASE_PRICE_CHANGER, _address);
    }

    function removeBasePriceChanger(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(BASE_PRICE_CHANGER, _address);
    }

    function setOVRLandExperienceAddress(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        OVRLandExperience = IOVRLandExperience(_address);
    }

    // admin can change feePerc
    function setFeePerc(uint256 _feePerc) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feePerc = _feePerc;
    }

    function setFeeReceiver(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeReceiver = _account;
    }

    /* ========== NO RENT ========== */

    /**
     * @dev Callable from OVRLand owner to prevent renters from
     * independently accepting offers of 1 month duration.
     * @param _nftId token id
     */
    function activateNoRent(
        IOVRERC721 _address,
        uint256 _nftId,
        NoRentParams calldata _noRentParams
    ) public isAllowedAddress(_address) whenNotPaused {
        require(_msgSender() == _address.ownerOf(_nftId), "Not the owner");
        if (_address == OVRLand) {
            // prettier-ignore
            require( token.transferFrom(_msgSender(), feeReceiver, noRentPriceLand), "Transfer failed");
        } else {
            // prettier-ignore
            require(token.transferFrom(_msgSender(), feeReceiver, noRentPriceContainer), "Transfer failed");
        }

        noRentsEnd[_address][_nftId] = _now().add(noRentDuration);
        noRentsParams[_address][_nftId] = _noRentParams;

        // prettier-ignore
        emit NoRentActivated(address(_address), _nftId, _msgSender(), _now(), noRentsEnd[_address][_nftId], noRentsParams[_address][_nftId].pricePerMonth, noRentsParams[_address][_nftId].minMonths, noRentsParams[_address][_nftId].maxMonths);
    }

    function activateNoRentFromHosting(
        IOVRERC721 _address,
        uint256 _nftId,
        uint256 _monthsDuration
    ) public isAllowedAddress(_address) whenNotPaused {
        require(_msgSender() == OVRLandHosting, "Not authorized");
        uint256 expiration = _now().add(_monthsDuration.mul(30 days));
        noRentsEnd[_address][_nftId] = expiration;
        noRentsParams[_address][_nftId] = NoRentParams(2**256 - 1, 12, 12);
        // prettier-ignore
        emit NoRentActivated( address(_address), _nftId, _msgSender(), _now(), expiration, noRentsParams[_address][_nftId].pricePerMonth, noRentsParams[_address][_nftId].minMonths, noRentsParams[_address][_nftId].maxMonths);
    }

    /**
     * @dev Callable from OVRLand owner to turn off NoRent
     * @param _nftId token id
     */
    function deactivateNoRent(IOVRERC721 _address, uint256 _nftId)
        public
        isAllowedAddress(_address)
        whenNotPaused
    {
        require(_msgSender() == _address.ownerOf(_nftId), "Not the owner");

        delete noRentsEnd[_address][_nftId];
        delete noRentsParams[_address][_nftId];
        emit NoRentDeactivated(address(_address), _nftId, _msgSender(), _now());
    }

    /**
     * @dev admin can set the hosting contrat
     */
    function setHostingContract(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "Not valid address");
        OVRLandHosting = _address;
    }

    /**
     * @dev admin can set the priceLand contract
     */
    function setPriceLandAddress(IPriceLand _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceLand = _address;
    }

    /**
     * @dev Check if NoRent is active
     * @param _nftId token id
     * @return bool
     */
    function isNoRentActive(IOVRERC721 _address, uint256 _nftId)
        public
        view
        returns (bool)
    {
        if (noRentsEnd[_address][_nftId] == 0) {
            return false;
        }
        if (_now() < noRentsEnd[_address][_nftId]) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Callable by admin to write floorPrice
     * @param _price ovr price
     */
    function setOVRFloorPrice(uint256 _price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        floorPrice = _price;
    }

    /**
     * @dev Callable by admin to update NoRent price
     * @param _price NoRent price
     */
    function changeNoRentPriceLand(uint256 _price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        noRentPriceLand = _price;
    }

    /**
     * @dev Callable by admin to update NoRent price containers
     * @param _price NoRent price
     */
    function changeNoRentPriceContainer(uint256 _price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        noRentPriceContainer = _price;
    }

    /**
     * @dev Callable by admin to update NoRent duration
     * @param _duration NoRent duration
     */
    function changeNoRentDuration(uint256 _duration)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        noRentDuration = _duration;
    }

    function getRentingInfo(IOVRERC721 _address, uint256 _nftId)
        public
        view
        returns (
            bool _onRenting,
            NoRentParams memory _noRentParams,
            uint256 _expiration,
            Offer memory _offer,
            string memory _experience,
            uint256 _date,
            uint256 _duration,
            address _renter
        )
    {
        (_experience, _date, _duration, _renter) = OVRLandExperience
            .getExperienceInfo(_address, _nftId);

        return (
            OVRLandExperience.isTokenRented(_address, _nftId),
            noRentsParams[_address][_nftId],
            noRentsEnd[_address][_nftId],
            offers[_address][_nftId],
            _experience,
            _date,
            _duration,
            _renter
        );
    }

    /**
     * @dev Method to place new offer
     * This function can be called by everyone if no offer is present. If an offer already exists
     * it must be higher. Is allowed to overbid if 24 hours have not passed or after 7 days
     * (indicates that owner and renter are not active).
     * @param _nftAddress nft address
     * @param _nftId tokenId
     * @param _amountPerMonth OVR tokens per month
     * @param _months number of months
     * @param _uri experience uri
     */
    function placeOffer(
        IOVRERC721 _nftAddress,
        uint256 _nftId,
        uint256 _amountPerMonth,
        uint256 _months,
        string memory _uri
    )
        public
        isOfferBetter(_nftAddress, _nftId, _amountPerMonth)
        isAllowedAddress(_nftAddress)
        whenNotPaused
    {
        // prettier-ignore
        require(!OVRLandExperience.isTokenRented(_nftAddress, _nftId),"Still rented");
        require(
            _nftAddress.ownerOf(_nftId) != _msgSender(),
            "You are the owner"
        );
        require(_months > 0 && _months < 13, "Only 12 months interval");

        uint256 minPrice = basePrice(_nftAddress, _nftId) != 0
            ? basePrice(_nftAddress, _nftId)
            : _nftAddress == OVRContainer
            ? basePriceContainers
            : basePriceLands;

        require(
            _amountPerMonth >= minPrice,
            string(
                abi.encodePacked(
                    "Amount per month must be greater than or equal to ",
                    StringsUpgradeable.toString(minPrice)
                )
            )
        );
        placeOfferInternal(_nftAddress, _nftId, _amountPerMonth, _months, _uri);
    }

    function placeOfferInternal(
        IOVRERC721 _nftAddress,
        uint256 _nftId,
        uint256 _amountPerMonth,
        uint256 _months,
        string memory _uri
    ) internal nonReentrant {
        uint256 calculatedFees = (_amountPerMonth.mul(_months))
            .mul(feePerc)
            .div(1e4);
        if (offers[_nftAddress][_nftId].timestamp != 0) {
            // There is already an offer
            uint256 timestamp = offers[_nftAddress][_nftId].timestamp;
            if (
                _now() < timestamp.add(1 days) || _now() > timestamp.add(8 days)
            ) {
                // 24h not passed or 7 days passed
                repayPreviousOfferer(_nftAddress, _nftId);
                // prettier-ignore
                emit Overbid( address(_nftAddress), _nftId, _msgSender(), _amountPerMonth, _months, _now(), calculatedFees);
            } else {
                revert("Offer in acceptance");
            }
        } else {
            // No offer made until now
            // prettier-ignore
            emit OfferPlaced( address(_nftAddress), _nftId, _msgSender(), _amountPerMonth, _months, _now(), calculatedFees);
        }

        uint256 amountToSend = _amountPerMonth.mul(_months);

        require(
            token.transferFrom(_msgSender(), address(this), amountToSend),
            "Transfer failed"
        );

        // prettier-ignore
        saveOffer( _nftAddress, _nftId, _msgSender(), _amountPerMonth, calculatedFees, _months, _uri);
    }

    /* ========== OFFERS ========== */

    /**
     * @dev In the case of an overbid it returns the amount spent by the previous bidder.
     * @param _nftId token id
     */
    function repayPreviousOfferer(IOVRERC721 _address, uint256 _nftId)
        internal
        isAllowedAddress(_address)
    {
        if (offers[_address][_nftId].from != address(0)) {
            address from = offers[_address][_nftId].from;
            uint256 paid = offers[_address][_nftId].valuePerMonth.mul(
                offers[_address][_nftId].months
            );
            offers[_address][_nftId].from = address(0); // Improve safety
            // prettier-ignore
            require(token.transfer(from, paid), "Insufficient contract balance");
        }
    }

    /**
     * @dev Internal method to save new offer
     * @param _nftId tokenId
     * @param _sender created by
     * @param _amountPerMonth OVR tokens per month
     * @param _fee fee in OVR
     * @param _months number of months
     * @param _uri experience uri
     */
    // prettier-ignore
    function saveOffer( IOVRERC721 _nft, uint256 _nftId, address _sender, uint256 _amountPerMonth, uint256 _fee, uint256 _months, string memory _uri) internal {
        // prettier-ignore
        offers[_nft][_nftId] = Offer( _nft, _sender, _nftId, _amountPerMonth, _months, _fee, _now(), _uri);
    }

    /**
     * @dev Method to accept offer
     * The OVRLand owner may accept an offer at any time. If the offer has a duration
     * of 1 month also the renter can accept it if for more than 24 hours no new offers arrive.
     * In this case, the renter has 7 days to finalize the renting before new offers come to outbid him.
     *
     * This condition is present mainly to avoid a liability of the owner who may not be active
     * or may have lost his private keys.
     * @param _nftId tokenId
     */
    function acceptOffer(IOVRERC721 _address, uint256 _nftId)
        public
        whenNotPaused
        isAllowedAddress(_address)
    {
        require(
            _msgSender() == _address.ownerOf(_nftId) ||
                (_msgSender() == offers[_address][_nftId].from &&
                    _now() > offers[_address][_nftId].timestamp.add(3 days)),
            "Not authorized"
        );
        // prettier-ignore
        require(!OVRLandExperience.isTokenRented(_address, _nftId),"Still renting");
        require(offers[_address][_nftId].from != address(0), "Not valid offer");
        // prettier-ignore
        require(_now() > offers[_address][_nftId].timestamp.add(1 days), "24 hours not yet elapsed");
        // prettier-ignore
        require(_now() < offers[_address][_nftId].timestamp.add(8 days), "Acceptance time window of 7 days expired");
        // prettier-ignore
        require(_address.ownerOf(_nftId) != address(OVRContainer), "Land is inside a container");

        // owner can accept everytime
        if (_msgSender() != _address.ownerOf(_nftId)) {
            if (isNoRentActive(_address, _nftId)) {
                // if no rent is active, renter can accept only if period is acceptable and price is acceptable
                require(
                    noRentsParams[_address][_nftId].minMonths <=
                        offers[_address][_nftId].months &&
                        offers[_address][_nftId].months <=
                        noRentsParams[_address][_nftId].maxMonths,
                    "Invalid months number"
                );
                require(
                    noRentsParams[_address][_nftId].pricePerMonth <=
                        offers[_address][_nftId].valuePerMonth,
                    "No Rent"
                );
            } else {
                // if no rent isn't active, renter can accept only if period is = 1 month
                require(
                    offers[_address][_nftId].months == 1,
                    "Renter can't accept by itself for more than 1 month"
                );
            }
        }

        // prettier-ignore
        bool success = OVRLandExperience.startTokenRenting( _address, _nftId, offers[_address][_nftId].from, _now(), offers[_address][_nftId].months, offers[_address][_nftId].experienceUri);

        if (success) {
            uint256 tokenForOwner = (
                offers[_address][_nftId].valuePerMonth.mul(
                    offers[_address][_nftId].months
                )
            ).sub(offers[_address][_nftId].fee);

            token.transfer(_address.ownerOf(_nftId), tokenForOwner);
            token.transfer(feeReceiver, offers[_address][_nftId].fee);
            // prettier-ignore
            emit OfferAccepted( address(_address), _nftId, _msgSender(), offers[_address][_nftId].from, offers[_address][_nftId].valuePerMonth, offers[_address][_nftId].months, _now());

            delete offers[_address][_nftId];
        } else {
            revert("Error: OVRLandExperience.startTokenRenting");
        }
    }

    function cancelOffer(IOVRERC721 _address, uint256 _nftId)
        public
        isAllowedAddress(_address)
        whenNotPaused
        nonReentrant
    {
        require(
            _msgSender() == offers[_address][_nftId].from ||
                _msgSender() == _address.ownerOf(_nftId),
            "Not the offerer nor the owner"
        );

        if (_msgSender() == offers[_address][_nftId].from) {
            require(
                _now() > offers[_address][_nftId].timestamp.add(8 days) ||
                    _now() < offers[_address][_nftId].timestamp.add(1 days),
                "You can't cancel the offer now"
            );
        } else {
            require(
                _now() > offers[_address][_nftId].timestamp.add(1 days),
                "24 hours not yet elapsed"
            );
        }
        repayPreviousOfferer(_address, _nftId);
        delete offers[_address][_nftId];
        emit OfferCanceled(address(_address), _nftId, _msgSender(), _now());
    }

    function changeBasePriceLands(uint256 _newBasePriceLands)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        basePriceLands = _newBasePriceLands;
    }

    function changeBasePriceContainers(uint256 _newBasePriceContainers)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        basePriceContainers = _newBasePriceContainers;
    }

    function basePrice(IOVRERC721 _address, uint256 _id)
        public
        view
        returns (uint256)
    {
        if (priceLand != IPriceLand(address(0))) {
            uint256 price = priceLand.getPrice(_address, _id);
            return price;
        } else {
            if (_address == OVRContainer) {
                return basePriceContainers;
            } else {
                return basePriceLands;
            }
        }
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
