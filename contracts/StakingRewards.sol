//SPDX-License-Identifier: MIT
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
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract StakingRewards is
  UUPSUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using AddressUpgradeable for address;
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  mapping(address => mapping(address => uint256)) public ovrSpent;
  mapping(address => uint256) public totalOvrSpent;

  IERC20Upgradeable public ovr;

  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

  function initialize(IERC20Upgradeable _ovr) public initializer {
    ovr = _ovr;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // prettier-ignore
  event Withdrawn(address indexed from, address indexed to, uint256 indexed amount);
  event Deposited(address indexed from, uint256 indexed amount);

  /* ========== FUNCTIONS ========== */

  /**
   * @dev Function to deposit OVR tokens to staking rewards contract, callable by anyone.
   * @param _account Deposit for the account
   * @param _amount Amount of OVR to deposit.
   */
  function deposit(address _account, uint256 _amount) public nonReentrant {
    // prettier-ignore
    require(ovr.transferFrom(_msgSender(), address(this), _amount), "Deposit error");
    balances[_account] = balances[_account].add(_amount);
    emit Deposited(_account, _amount);
  }

  /**
   * @dev Get the balance of the given address.
   * @param _account Account to get the balance of.
   * @return balance of the given account.
   */
  function availableBalance(address _account)
    public
    view
    returns (uint256 balance)
  {
    return balances[_account];
  }

  /**
   * @dev only WITHDRAWER_ROLE can withdraw.
   * @param _accountFrom Account to withdraw from.
   * @param _accountTo Withdraw to.
   * @param _amount Amount.
   */
  function withdraw(
    address _accountFrom,
    address _accountTo,
    uint256 _amount
  ) public onlyRole(WITHDRAWER_ROLE) nonReentrant {
    require(balances[_accountFrom] > _amount, "Not enough balance");
    balances[_accountFrom] = balances[_accountFrom].sub(_amount);
    ovrSpent[_accountFrom][msg.sender] = ovrSpent[_accountFrom][_msgSender()]
      .add(_amount);
    totalOvrSpent[_accountFrom] = totalOvrSpent[_accountFrom].add(_amount);
    ovr.transfer(_accountTo, _amount);
    emit Withdrawn(_accountFrom, msg.sender, _amount);
  }

  function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function addWithdrawerRole(address _withdrawer)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(WITHDRAWER_ROLE, _withdrawer);
  }

  // prettier-ignore
  function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE){}
}
