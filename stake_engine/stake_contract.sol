// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function getRewards() external view returns (uint256);
    function claimRewards() external;
}

contract TokenStakingSplitter is ReentrancyGuard {
    address public contractOwner;
    IERC20 public token;
    
    mapping(address => uint256) public userDeposits;
    uint256 public tokenOwnerSplitRate; // 0-100
    address public stakingContract;
    bool public isStakable;

    event TokensReceived(address from, uint256 amount);
    event RewardsSplit(address tokenOwner, uint256 tokenOwnerAmount, uint256 contractOwnerAmount);
    event SplitRateUpdated(uint256 newRate);

    constructor(address _tokenAddress, uint256 _initialSplitRate) {
        contractOwner = msg.sender;
        token = IERC20(_tokenAddress);
        tokenOwnerSplitRate = _initialSplitRate;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this");
        _;
    }

    // Function to receive tokens with reentrancy guard
    function depositTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        userDeposits[msg.sender] += _amount;
        emit TokensReceived(msg.sender, _amount);

        if (isStakable && stakingContract != address(0)) {
            token.approve(stakingContract, _amount);
            IStaking(stakingContract).stake(_amount);
        }
    }

    // Set staking contract address and verify it
    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
        isStakable = checkStakable();
    }

    function updateSplitRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 100, "Rate must be between 0 and 100");
        tokenOwnerSplitRate = _newRate;
        emit SplitRateUpdated(_newRate);
    }

    // Distribute rewards with reentrancy guard
    function distributeRewards() external nonReentrant {
        require(isStakable && stakingContract != address(0), "Staking not enabled");
        
        uint256 rewards = IStaking(stakingContract).getRewards();
        require(rewards > 0, "No rewards available");

        IStaking(stakingContract).claimRewards();

        uint256 tokenOwnerShare = (rewards * tokenOwnerSplitRate) / 100;
        uint256 contractOwnerShare = rewards - tokenOwnerShare;

        require(token.transfer(msg.sender, tokenOwnerShare), "Token owner transfer failed");
        require(token.transfer(contractOwner, contractOwnerShare), "Contract owner transfer failed");

        emit RewardsSplit(msg.sender, tokenOwnerShare, contractOwnerShare);
    }

    // Withdraw tokens with reentrancy guard
    function withdrawTokens(uint256 _amount) external nonReentrant {
        require(userDeposits[msg.sender] >= _amount, "Insufficient balance");

        userDeposits[msg.sender] -= _amount;

        if (isStakable && stakingContract != address(0)) {
            IStaking(stakingContract).unstake(_amount);
        }

        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    // Enhanced function to check if token can be staked
    function checkStakable() public view returns (bool) {
        if (stakingContract == address(0)) {
            return false;
        }

        // Try to verify if the staking contract is valid
        try IStaking(stakingContract).isStakingContract() returns (bool isValid) {
            if (!isValid) {
                return false;
            }
        } catch {
            return false; // If the call fails, assume it's not stakable
        }

        // Check if this contract has sufficient allowance to interact with staking
        uint256 allowance = token.allowance(address(this), stakingContract);
        if (allowance == 0) {
            return false;
        }

        // Check if staking contract has a valid getRewards function
        try IStaking(stakingContract).getRewards() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
}
