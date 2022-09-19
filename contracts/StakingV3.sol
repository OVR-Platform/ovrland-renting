//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "hardhat/console.sol";

// INTERFACE
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IStakingRewards.sol";

// LIB
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// CONTRACTS
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract StakingV3 is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    mapping(address => mapping(uint256 => StakeDeposits)) public deposits;
    mapping(uint256 => LockPeriodParams) public lockPeriod;

    bool private contractPaused;
    bool private depositsAndLockupExtensionsPaused;

    IERC20Upgradeable public OVRToken;
    address public liquidityProvider;
    IStakingRewards public stakingRewards;

    uint256 private constant DAY = 1 days;
    uint256 private constant MONTH = 30 days;

    // prettier-ignore
    struct StakeDeposits { uint256 balance; uint256 timestamp; uint256 lastReward;}
    // prettier-ignore
    struct LockPeriodParams {uint256 duration;uint256 ratio;uint256 maxTokens;uint256 tokensDeposited;}

    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when a user deposits tokens.
     * @param sender User address.
     * @param id User's unique deposit ID.
     * @param amount The amount of deposited tokens.
     * @param currentBalance Current user balance.
     * @param timestamp Operation date
     */
    // prettier-ignore
    event Deposited(address indexed sender, uint256 indexed id, uint256 amount, uint256 currentBalance, uint256 timestamp);

    /**
     * @dev Emitted when a user withdraws tokens.
     * @param sender User address.
     * @param id User's unique deposit ID.
     * @param totalWithdrawalAmount The total amount of withdrawn tokens.
     * @param currentBalance Balance before withdrawal
     * @param timestamp Operation date
     */
    // prettier-ignore
    event DepositWithdraw(address indexed sender, uint256 indexed id, uint256 totalWithdrawalAmount, uint256 currentBalance, uint256 timestamp);

    /**
     * @dev Emitted when a user withdraws rewards.
     * @param sender User address.
     * @param id User's unique deposit ID.
     * @param totalRewardsWithdrawn The total amount of withdrawn tokens.
     * @param currentBalance Balance before withdrawal
     * @param timestamp Operation date
     */
    // prettier-ignore
    event WithdrawnRewards(address indexed sender, uint256 indexed id, uint256 totalRewardsWithdrawn, uint256 currentBalance, uint256 timestamp);

    /**
     * @dev Emitted when a user extends lockup.
     * @param sender User address.
     * @param id User's unique deposit ID.
     * @param currentBalance Balance before lockup extension
     * @param timestamp The instant when the lockup is extended.
     */
    // prettier-ignore
    event ExtendedLockup(address indexed sender, uint256 indexed id, uint256 currentBalance, uint256 timestamp);

    /**
     * @dev Emitted when a new Liquidity Provider address value is set.
     * @param account A new address value.
     */
    event LiquidityProviderUpdated(address indexed account);

    /* ========== INITIALIZER ========== */

    /**
     * @dev Initializes the contract. _tokenAddress _token will have the same address
     * @param _tokenAddress The address of the OVR token contract.
     * @param _liquidityProviderAddress The address for the Liquidity Providers reward.
     */
    function initialize(
        address _tokenAddress,
        address _liquidityProviderAddress,
        address _stakingRewardsAddress
    ) external initializer {
        require(_tokenAddress.isContract(), "Not a contract address");
        __AccessControl_init();
        __ReentrancyGuard_init();
        setLockupParams();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        OVRToken = IERC20Upgradeable(_tokenAddress);
        setLiquidityProviderAddress(_liquidityProviderAddress);
        setStakingRewards(IStakingRewards(_stakingRewardsAddress));

        contractPaused = false;
        depositsAndLockupExtensionsPaused = false;
    }

    /* ========== MODIFIERS ========== */

    /*
     *      1   |     2    |     3    |     4    |     5
     * 0 Months | 3 Months | 6 Months | 9 Months | 12 Months
     */
    modifier validDepositId(uint256 _depositId) {
        require(_depositId >= 1 && _depositId <= 5, "Invalid depositId");
        _;
    }

    // Impossible to withdrawAll if you have never deposited.
    modifier balanceExists(uint256 _depositId) {
        // prettier-ignore
        require(deposits[_msgSender()][_depositId].balance > 0, "Your deposit is zero");
        _;
    }

    /* ========== PAUSE ========== */

    modifier isNotPaused() {
        require(contractPaused == false, "Paused");
        _;
    }

    modifier isNotPausedDepositAndLockupExtensions() {
        // prettier-ignore
        require(depositsAndLockupExtensionsPaused == false, "Paused Deposits and Extensions");
        _;
    }

    /**
     * @dev Pause Deposits, Withdraw, Lockup Extension
     * @param _value boolean
     */
    function pauseContract(bool _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractPaused = _value;
    }

    /**
     * @dev Pause Deposits and Lockup Extension
     * @param _value boolean
     */
    function pauseDepositAndLockupExtensions(bool _value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        depositsAndLockupExtensionsPaused = _value;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * This method is calcuate final rewards.
     * @param _principal User's balance
     * @param _ratio Interest rate
     * @param _n Periods is timestamp
     * @return uint256 The final rewards
     *
     * A = [ C ( 1 + rate )^t ]- C
     */
    function compound(
        uint256 _principal,
        uint256 _ratio,
        uint256 _n
    ) public pure returns (uint256) {
        uint256 daysCount = _n.div(DAY);

        uint256 totalBalanceCompounded = ABDKMath64x64.mulu(
            pow(
                ABDKMath64x64.add(
                    ABDKMath64x64.fromUInt(1),
                    ABDKMath64x64.divu(_ratio, 10**18)
                ),
                daysCount
            ),
            _principal
        );

        if (totalBalanceCompounded > _principal) {
            return totalBalanceCompounded.sub(_principal);
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns user depositId balance
     * @param _depositId The deposit id
     * @param _account Account
     * @return uint256 the balance of the address.
     */
    function balanceOf(uint256 _depositId, address _account)
        public
        view
        returns (uint256)
    {
        return deposits[_account][_depositId].balance;
    }

    /**
     * @dev Returns user last reward timestamp
     * @param _depositId The deposit id
     * @param _account Account
     * @return uint256 last reward timestamp.
     */
    function lastReward(uint256 _depositId, address _account)
        public
        view
        returns (uint256)
    {
        return deposits[_account][_depositId].lastReward;
    }

    /**
     * @dev Returns user deposit timestamp
     * @param _depositId The deposit id
     * @param _account Account
     * @return uint256 last deposit timestamp
     */
    function depositTimestamp(uint256 _depositId, address _account)
        public
        view
        returns (uint256)
    {
        return deposits[_account][_depositId].timestamp;
    }

    /**
     * @dev Returns lock duration based on deposit id
     * @param _depositId The deposit id
     * @return uint256 duration
     */
    function lockDuration(uint256 _depositId) public view returns (uint256) {
        return lockPeriod[_depositId].duration;
    }

    /**
     * This moethod is used to calculate compounded balance and is based on deposit duration and deposit id.
     * Each deposit mode is characterized by the lockup period and interest rate.
     * At the expiration of the lockup period the final compounded capital
     * will use minimum interest rate.
     *
     * This function can be called at any time to get the current total reward.
     * @param _account Sender Address.
     * @param _depositId The depositId
     * @return uint256 The final rewards
     */
    function calcRewards(address _account, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (uint256)
    {
        if (balanceOf(_depositId, _account) == 0) {
            return 0;
        }

        bool alreadyClaimedRewards = lastReward(_depositId, _account) != 0;

        if (_depositId == 1) {
            return
                // prettier-ignore
                compound(balanceOf(_depositId, _account), lockPeriod[1].ratio, // minimum rate
                    alreadyClaimedRewards
                        ? _now().sub(lastReward(_depositId, _account))
                        : _now().sub(depositTimestamp(_depositId, _account))
                );
        }

        // prettier-ignore
        bool lockupExpired = _now() > depositTimestamp(_depositId, _account).add(lockDuration(_depositId));

        if (!alreadyClaimedRewards) {
            if (lockupExpired) {
                return
                    // prettier-ignore
                    compound(balanceOf(_depositId, _account), lockPeriod[_depositId].ratio, lockDuration(_depositId))
                    + compound(balanceOf(_depositId, _account),lockPeriod[1].ratio, _now().sub(lockDuration(_depositId).add(depositTimestamp(_depositId, _account))));
            }

            return
                // prettier-ignore
                compound(balanceOf(_depositId, _account), lockPeriod[_depositId].ratio, _now().sub(depositTimestamp(_depositId, _account)));
        }

        if (lockupExpired) {
            if (
                // prettier-ignore
                lastReward(_depositId, _account) >
                depositTimestamp(_depositId, _account).add(lockDuration(_depositId))
            ) {
                // if the last claim timestamp occurred after the end of the lockup, select only
                // the part between last reward and now() at the minimum interest rate.
                return
                    compound(
                        balanceOf(_depositId, _account),
                        lockPeriod[1].ratio,
                        _now().sub(lastReward(_depositId, _account))
                    );
            }

            // if the last claim timestamp occurred before the end of lockup, select between the
            // last reward and the end of lockup with regular interest rate and from the
            // end of lockup to date at the minimum interest rate.
            return
                compound(
                    balanceOf(_depositId, _account),
                    lockPeriod[_depositId].ratio,
                    depositTimestamp(_depositId, _account)
                        .add(lockDuration(_depositId))
                        .sub(lastReward(_depositId, _account))
                ) +
                compound(
                    balanceOf(_depositId, _account),
                    lockPeriod[1].ratio,
                    _now().sub(
                        depositTimestamp(_depositId, _account).add(
                            lockDuration(_depositId)
                        )
                    )
                );
        }

        return
            compound(
                balanceOf(_depositId, _account),
                lockPeriod[_depositId].ratio,
                _now().sub(lastReward(_depositId, _account))
            );
    }

    function isLockupPeriodExpired(address _account, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (bool)
    {
        return
            _now() >
            deposits[_account][_depositId].timestamp.add(
                lockPeriod[_depositId].duration
            );
    }

    function pow(int128 _x, uint256 _n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt(1);
        while (_n > 0) {
            if (_n % 2 == 1) {
                r = ABDKMath64x64.mul(r, _x);
                _n -= 1;
            } else {
                _x = ABDKMath64x64.mul(_x, _x);
                _n /= 2;
            }
        }
    }

    /**
     * @dev This method is used to deposit tokens.
     * It calls the internal "_deposit" method and transfers tokens from sender to contract.
     * Sender must approve tokens first.
     *
     * @param _depositId User's unique deposit ID.
     * @param _amount The amount to deposit.
     */
    function deposit(uint256 _depositId, uint256 _amount)
        public
        validDepositId(_depositId)
        isNotPaused
        isNotPausedDepositAndLockupExtensions
    {
        require(_amount > 0, "Amount should be more than 0");

        _deposit(_depositId, _amount);
    }

    /**
     * @param _depositId User's deposit ID.
     * @param _amount The amount to deposit.
     */
    function _deposit(uint256 _depositId, uint256 _amount)
        internal
        nonReentrant
    {
        require(
            lockPeriod[_depositId].tokensDeposited.add(_amount) <=
                lockPeriod[_depositId].maxTokens,
            "Too many tokens deposited"
        );
        lockPeriod[_depositId].tokensDeposited = lockPeriod[_depositId]
            .tokensDeposited
            .add(_amount);
        uint256 currentBalance = balanceOf(_depositId, _msgSender());
        if (balanceOf(_depositId, _msgSender()) > 0) {
            _withdrawRewards(_depositId);
        }

        // prettier-ignore
        deposits[_msgSender()][_depositId].balance = _amount.add(currentBalance);
        deposits[_msgSender()][_depositId].timestamp = _now();
        deposits[_msgSender()][_depositId].lastReward = 0;

        require(
            OVRToken.transferFrom(_msgSender(), address(this), _amount),
            "Transfer failed"
        );

        // prettier-ignore
        emit Deposited(_msgSender(), _depositId, _amount, currentBalance,_now());
    }

    /**
     * @dev This method is used to withdraw rewards.
     * @param _depositId User's deposit ID.
     */
    function withdrawRewards(uint256 _depositId)
        public
        balanceExists(_depositId)
        validDepositId(_depositId)
        isNotPaused
        nonReentrant
    {
        _withdrawRewards(_depositId);
    }

    /**
     * @dev This method is used to withdraw rewards accumulated
     * and deposit them on StakingRewards contract.
     * @param _depositId User's deposit ID.
     */
    function _withdrawRewards(uint256 _depositId) internal {
        uint256 rewards = calcRewards(_msgSender(), _depositId);
        require(rewards > 0, "Nothing to claim");
        require(
            OVRToken.transferFrom(liquidityProvider, address(this), rewards),
            "transfer failed"
        );

        deposits[_msgSender()][_depositId].lastReward = _now();
        stakingRewards.deposit(_msgSender(), rewards);

        // prettier-ignore
        emit WithdrawnRewards(_msgSender(), _depositId, rewards, balanceOf(_depositId, _msgSender()), _now());
    }

    /**
     * @dev This method is used to withdraw rewards and balance.
     * It calls the internal "_withdrawAll" method.
     * @param _depositId User's unique deposit ID
     */
    function withdrawAll(uint256 _depositId)
        external
        balanceExists(_depositId)
        validDepositId(_depositId)
        isNotPaused
    {
        require(
            isLockupPeriodExpired(_msgSender(), _depositId),
            "Too early, Lockup period"
        );
        _withdrawAll(_depositId);
    }

    function _withdrawAll(uint256 _depositId)
        internal
        balanceExists(_depositId)
        validDepositId(_depositId)
        nonReentrant
    {
        uint256 currentBalance = balanceOf(_depositId, _msgSender());

        lockPeriod[_depositId].tokensDeposited = lockPeriod[_depositId]
            .tokensDeposited
            .sub(currentBalance);

        uint256 rewards = calcRewards(_msgSender(), _depositId);

        // possibilità di ritirare il balance anche con 0 rewards
        require(currentBalance.add(rewards) > 0, "Nothing to withdraw");
        delete deposits[_msgSender()][_depositId];

        require(
            OVRToken.transfer(_msgSender(), currentBalance),
            "Liquidity pool transfer failed"
        );

        require(
            OVRToken.transferFrom(liquidityProvider, address(this), rewards),
            "transfer failed"
        );

        // deposit rewards in staking rewards
        stakingRewards.deposit(_msgSender(), rewards);

        // prettier-ignore
        emit DepositWithdraw(_msgSender(), _depositId, rewards, currentBalance, _now());
    }

    /**
     * @dev Sets the address for the Liquidity Providers reward.
     * Can only be called by an admin.
     * @param _address The new address.
     */
    function setLiquidityProviderAddress(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "Zero address");
        require(_address != address(this), "Wrong address");
        liquidityProvider = _address;
        emit LiquidityProviderUpdated(_address);
    }

    function liquidityProviderAddress() public view returns (address) {
        return liquidityProvider;
    }

    function setStakingRewards(IStakingRewards _rewards)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakingRewards = _rewards;
        OVRToken.approve(address(stakingRewards), 2**256 - 1);
    }

    /**
     * @dev This method is used to get the number of total token deposited for each depositId.
     * @param _depositId The deposit id
     * @return uint256
     */
    function tokensDeposited(uint256 _depositId) public view returns (uint256) {
        return lockPeriod[_depositId].tokensDeposited;
    }

    /**
     * Update max amount tokens per tier
     * @param _depositId deposit id
     * @param _maxTokens max amount per tier
     */
    function changeMaxTokens(uint256 _depositId, uint256 _maxTokens)
        external
        validDepositId(_depositId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_maxTokens > 0, "Amount should be more than 0");
        lockPeriod[_depositId].maxTokens = _maxTokens;
    }

    /**
     * This method is used to extend lockup. It is available if your lockup period is expired and if depositId != 1
     * It calls the internal "_extendLockup" method.
     * @param _depositId User's unique deposit id
     */
    function extendLockup(uint256 _depositId)
        external
        balanceExists(_depositId)
        validDepositId(_depositId)
        isNotPaused
        isNotPausedDepositAndLockupExtensions
    {
        require(_depositId > 1 && _depositId < 6, "depositId between 2 and 5");
        _extendLockup(_depositId);
    }

    function _extendLockup(uint256 _depositId) internal nonReentrant {
        _withdrawRewards(_depositId);

        deposits[_msgSender()][_depositId].timestamp = _now();

        // prettier-ignore
        emit ExtendedLockup(_msgSender(), _depositId, deposits[_msgSender()][_depositId].balance, _now());
    }

    function setLockupParams() internal {
        uint256 tokensLock1 = 100000;
        uint256 tokensLock2 = 100000;
        uint256 tokensLock3 = 100000;
        uint256 tokensLock4 = 100000;
        uint256 tokensLock5 = 100000;

        // prettier-ignore
        // No Lockup - APY 3.7% InterestRate = 0.01
        lockPeriod[1] = LockPeriodParams(0, 0.0001 ether, tokensLock1.mul(1e18), 0);

        // prettier-ignore
        // 3 months Lockup - APY 11.6% InterestRate = 0.03
        lockPeriod[2] = LockPeriodParams(MONTH * 3, 0.0003 ether, tokensLock2.mul(1e18), 0);

        // prettier-ignore
        // 6 months Lockup - APY 15.7% InterestRate = 0.04
        lockPeriod[3] = LockPeriodParams(MONTH * 6, 0.0004 ether, tokensLock3.mul(1e18), 0);

        // prettier-ignore
        // 9 months Lockup - APY 25.5% InterestRate = 0.06
        lockPeriod[4] = LockPeriodParams(MONTH * 9, 0.0006 ether, tokensLock4.mul(1e18), 0);

        // prettier-ignore
        // 12 months Lockup - APY 33.9% InterestRate = 0.08
        lockPeriod[5] = LockPeriodParams(MONTH * 12, 0.0008 ether, tokensLock5.mul(1e18), 0);
    }

    /**
     * @return Returns current timestamp.
     */
    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    // prettier-ignore
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE){}
}
