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

contract TokenStakingSplitter is ReentrancyGuard {
    address public contractOwner;
    IERC20 public token;
    
    // Mapping to track user deposits
    mapping(address => uint256) public userDeposits;
    // Variable split rate (percentage to token owner, rest goes to contract owner)
    uint256 public tokenOwnerSplitRate; // 0-100
    
    // Staking contract address (if token supports staking)
    address public stakingContract;
    bool public isStakable;

    event TokensReceived(address from, uint256 amount);
    event RewardsSplit(address tokenOwner, uint256 tokenOwnerAmount, uint256 contractOwnerAmount);
    event SplitRateUpdated(uint256 newRate);

    constructor(address _tokenAddress, uint256 _initialSplitRate) {
        contractOwner = msg.sender;
        token = IERC20(_tokenAddress);
        tokenOwnerSplitRate = _initialSplitRate;
        // Staking contract address would need to be set separately if applicable
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this");
        _;
    }

    // Function to receive tokens
    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from sender to contract
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        userDeposits[msg.sender] += _amount;
        emit TokensReceived(msg.sender, _amount);

        // If token is stakable and staking contract is set, stake the tokens
        if (isStakable && stakingContract != address(0)) {
            token.approve(stakingContract, _amount);
            IStaking(stakingContract).stake(_amount);
        }
    }

    // Set staking contract address and enable staking
    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
        isStakable = true;
    }

    // Update split rate
    function updateSplitRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 100, "Rate must be between 0 and 100");
        tokenOwnerSplitRate = _newRate;
        emit SplitRateUpdated(_newRate);
    }

    // Check available rewards and split them
    function distributeRewards() external {
        require(isStakable && stakingContract != address(0), "Staking not enabled");
        
        uint256 rewards = IStaking(stakingContract).getRewards();
        require(rewards > 0, "No rewards available");

        // Claim rewards from staking contract
        IStaking(stakingContract).claimRewards();

        // Calculate split
        uint256 tokenOwnerShare = (rewards * tokenOwnerSplitRate) / 100;
        uint256 contractOwnerShare = rewards - tokenOwnerShare;

        // Distribute rewards
        require(token.transfer(msg.sender, tokenOwnerShare), "Token owner transfer failed");
        require(token.transfer(contractOwner, contractOwnerShare), "Contract owner transfer failed");

        emit RewardsSplit(msg.sender, tokenOwnerShare, contractOwnerShare);
    }

    // Withdraw original tokens (unstake if staked)
    function withdrawTokens(uint256 _amount) external {
        require(userDeposits[msg.sender] >= _amount, "Insufficient balance");

        userDeposits[msg.sender] -= _amount;

        if (isStakable && stakingContract != address(0)) {
            IStaking(stakingContract).unstake(_amount);
        }

        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    // Check if token can be staked (work to be done)
    function checkStakable() public view returns (bool) {
        return isStakable;
    }
}


