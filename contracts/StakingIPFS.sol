// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract StakingIPFS is Context {
    IERC20 public ovr;
    mapping(address => Stake) public balances;
    uint256 public amount;

    constructor(IERC20 _ovr) {
        ovr = _ovr;
        amount = 500000 ether;
    }

    event StakeDeposit(address indexed staker, uint256 timestamp);
    event StakeWithdraw(address indexed staker, uint256 timestamp);

    struct Stake {
        uint256 balance;
        uint256 timestamp;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function onStaking(address _owner) public view returns (bool) {
        return balances[_owner].balance != 0;
    }

    function stakingExpiration(address _staker) public view returns (uint256) {
        return balances[_staker].timestamp + 12 * 30 days;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake() public {
        require(ovr.balanceOf(_msgSender()) >= amount, "At least 500k OVR");
        require(balances[_msgSender()].balance == 0, "Already staked");
        require(
            ovr.transferFrom(_msgSender(), address(this), amount),
            "insufficent allowance"
        );
        balances[_msgSender()] = Stake(amount, _now());
        emit StakeDeposit(_msgSender(), _now());
    }

    function withdraw() public {
        require(onStaking(_msgSender()), "Nothing staked");
        require(
            balances[_msgSender()].timestamp + 12 * 30 days <= _now(),
            "12 months lockup not yet expired"
        );

        uint256 currentBalance = balances[_msgSender()].balance;
        delete balances[_msgSender()];
        require(
            ovr.transfer(_msgSender(), currentBalance),
            "insufficent allowance"
        );
        emit StakeWithdraw(_msgSender(), _now());
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }
}
