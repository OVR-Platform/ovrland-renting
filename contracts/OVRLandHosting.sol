//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; // Includes Intialize, Context
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../contracts/PriceCalculator.sol";

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "../interfaces/IOVRERC721.sol";
import "../interfaces/IOVRLandRenting.sol";
import "../interfaces/IStakingRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OVRLandHosting is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PriceCalculator
{
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    mapping(uint256 => Tier) public tiers;
    mapping(uint256 => Payment) public payments;

    IOVRLandRenting public landRenting;
    IOVRERC721 public land;
    address public treasury;
    IERC20 public OVR;
    IStakingRewards public stakingRewards;

    uint256[] public IDs;

    struct Tier {
        uint256 price; // ovr price
        uint256 weight; // experience weight in megabyte
        uint256 duration; // number of months
        bool active; // is active right now
    }

    struct Payment {
        uint256 timestamp; // timestamp of payment
        uint256 weight; // weight of file
        uint256 duration; // number of months
        uint256 spent; // ovr spent
    }

    // prettier-ignore
    enum Parameter {price, weight, duration}

    /* ========== EVENTS ========== */

    // prettier-ignore
    event TierAdded(uint256 indexed id, uint256 price, uint256 weight, uint256 duration, uint256 timestamp);
    // prettier-ignore
    event TierRemoved(uint256 indexed id, uint256 timestamp);
    // prettier-ignore
    event TierUpdated(uint256 indexed id, Parameter parameter, uint256 input,uint256 timestamp);
    // prettier-ignore
    event FeesPaid(uint256 indexed nftId,uint256 tierId,address caller,uint256 timestamp);

    /* ========== VIEW FUNCTIONS ========== */

    function hostingFeesPaid(uint256 _nftId) public view returns (bool) {
        return
            _now() >= payments[_nftId].timestamp &&
            _now() <=
            payments[_nftId].timestamp.add(
                payments[_nftId].duration.mul(30 days)
            );
    }

    function hostingExpiration(uint256 _nftId) public view returns (uint256) {
        return
            payments[_nftId].timestamp.add(
                payments[_nftId].duration.mul(30 days)
            );
    }

    function viewTier(uint256 _tierId) public view returns (Tier memory) {
        return tiers[_tierId];
    }

    /**
     * @dev function to get all the active tiers
     * @return array of active tiers
     */
    function availableTiers() public view returns (uint256[] memory) {
        uint256[] memory aviableTiers;
        for (uint256 i = 0; i < IDs.length; i++) {
            if (tiers[IDs[i]].active) {
                aviableTiers[i] = IDs[i];
            }
        }
        return aviableTiers;
    }

    function ovrPrice() public view returns (uint256) {
        uint256 priceOvr = valueOfAsset(1);
        return priceOvr;
    }

    function stakingRewardsConfigured() public view returns (bool) {
        return stakingRewards != IStakingRewards(address(0));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        IOVRLandRenting _landRenting,
        IOVRERC721 _land,
        address _treasury,
        IERC20 _OVR
    ) public initializer {
        landRenting = _landRenting;
        land = _land;
        treasury = _treasury;
        OVR = _OVR;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setStakingRewards(IStakingRewards _stakingRewards)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakingRewards = _stakingRewards;
    }

    /**
     * @dev Creates a new tier.
     * @param _tierId tier id
     * @param _price1e18 USD price (usd price * 1e18)
     * @param _duration number of months
     * @param _weight experience weight in megabyte
     * @param _active is active right now
     */
    function addTier(
        uint256 _tierId,
        uint256 _price1e18,
        uint256 _duration,
        uint256 _weight,
        bool _active
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_duration > 0, "Duration must be greater than 0");
        require(_weight > 0, "Weight must be greater than 0");
        require(tiers[_tierId].price == 0, "Tier already exists");

        tiers[_tierId] = Tier(_price1e18, _weight, _duration, _active);
        IDs.push(_tierId);
        emit TierAdded(_tierId, _price1e18, _weight, _duration, _now());
    }

    function removeTier(uint256 _tierId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete tiers[_tierId];
        emit TierRemoved(_tierId, _now());
    }

    /**
     * @dev function to update parameters of a tier, only available to admin
     * parameter 0 => price
     * parameter 1 => weight
     * parameter 2 => duration
     * @param _tierId id of the tier
     * @param _parameter parameter to update
     * @param _input value to set
     */
    function updateTier(
        Parameter _parameter,
        uint256 _input,
        uint256 _tierId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_parameter == Parameter.price) {
            // 0
            tiers[_tierId].price = _input;
        } else if (_parameter == Parameter.weight) {
            // 1
            require(_input > 0, "Weight must be greater than 0");
            tiers[_tierId].weight = _input;
        } else if (_parameter == Parameter.duration) {
            // 2
            require(_input > 0, "Duration must be greater than 0");
            tiers[_tierId].duration = _input;
        }
        emit TierUpdated(_tierId, _parameter, _input, _now());
    }

    /**
     * @dev function to pay hosting fees and activate tier, if the msg.sender is the owner of the land,
     * the noRent service will be automatically activated for the hosting period.
     * @param _tier id of the tier
     * @param _nftId id of the nft
     */
    function payFees(
        uint256 _nftId,
        uint256 _tier,
        bool _activateNoRent
    ) public nonReentrant {
        require(tiers[_tier].active, "Tier not active");
        require(land.ownerOf(_nftId) != address(0), "NFT doesn't exist");
        uint256 ovrToPay = tiers[_tier].price.div(ovrPrice());
        uint256 stakingRewardsAvailable;

        if (stakingRewardsConfigured()) {
            stakingRewardsAvailable = stakingRewards.availableBalance(
                _msgSender()
            );
        }

        if (stakingRewardsConfigured() && stakingRewardsAvailable >= ovrToPay) {
            stakingRewards.withdraw(_msgSender(), treasury, ovrToPay);
        } else {
            if (stakingRewardsAvailable > 0) {
                // prettier-ignore
                stakingRewards.withdraw(_msgSender(), treasury, stakingRewardsAvailable);
                uint256 remainingTokens = ovrToPay.sub(stakingRewardsAvailable);

                // prettier-ignore
                require(OVR.balanceOf(_msgSender()) >= remainingTokens, "Not enough OVR");
                // prettier-ignore
                require(OVR.transferFrom(_msgSender(), treasury, remainingTokens), "Insufficent allowance");
            } else {
                // prettier-ignore
                require(OVR.balanceOf(_msgSender()) >= ovrToPay, "Not enough OVR");
                // prettier-ignore
                require(OVR.transferFrom(_msgSender(), treasury, ovrToPay), "Insufficent allowance");
            }
        }

        if (_msgSender() == land.ownerOf(_nftId) && _activateNoRent) {
            // prettier-ignore
            // TODO TEMA DA CHIARIRE D&D
            landRenting.activateNoRentFromHosting(land, _nftId, tiers[_tier].duration);
        }

        // prettier-ignore
        payments[_nftId] = Payment( tiers[_tier].weight, tiers[_tier].duration, ovrToPay, _now());
        emit FeesPaid(_nftId, _tier, _msgSender(), _now());
    }

    function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function removeAdminRole(address _admin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function updateTreasury(address _treasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        treasury = _treasury;
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
