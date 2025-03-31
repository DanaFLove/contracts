// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleEthTumbler {
    mapping(address => uint256) public deposits;
    mapping(address => address) public destinationAddresses;
    uint256 public totalDeposited;
    uint256 public minParticipants = 3; // Minimum number of users before withdrawals
    uint256 public participantCount;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    // Deposit ETH and specify a destination address
    function deposit(address _destination) external payable {
        require(msg.value > 0, "Must send ETH");
        require(deposits[msg.sender] == 0, "Already deposited");

        deposits[msg.sender] = msg.value;
        destinationAddresses[msg.sender] = _destination;
        totalDeposited += msg.value;
        participantCount += 1;

        emit Deposited(msg.sender, msg.value);
    }

    // Withdraw ETH to destination addresses (simplified)
    function withdraw() external {
        require(participantCount >= minParticipants, "Not enough participants yet");
        address destination = destinationAddresses[msg.sender];
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No funds to withdraw");

        deposits[msg.sender] = 0; // Prevent re-entrancy
        (bool sent, ) = destination.call{value: amount}("");
        require(sent, "Failed to send ETH");

        emit Withdrawn(destination, amount);
    }

    // Fallback to receive ETH
    receive() external payable {}

// Note that no emergency withdrawal exists here.
}
