// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZkVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external view returns (bool);
}

contract EnhancedEthTumbler {
    IZkVerifier public immutable zkVerifier; // Immutable to save gas
    uint256 public constant FIXED_DEPOSIT = 0.1 ether;
    uint256 public constant MAX_DELAY_BLOCKS = 100;
    uint32 public minParticipants = 3; // Use uint32 for smaller storage
    uint32 public participantCount; // Reduced size

    struct Deposit {
        bytes32 commitment;
        uint32 depositBlock; // uint32 safe for ~136 years at 15s/block
        uint32 delayBlocks; // uint32 sufficient for MAX_DELAY_BLOCKS
        bool withdrawn;
    }

    mapping(address => Deposit) public deposits;
    mapping(bytes32 => bool) public nullifiers;

    // Simplified events to reduce gas
    event Deposited(bytes32 commitment);
    event Withdrawn(address recipient);

    constructor(address _zkVerifier) {
        zkVerifier = IZkVerifier(_zkVerifier);
    }

    // Pseudo-random delay with reduced gas
    function generateDelay(address sender) internal view returns (uint32) {
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, sender));
        return uint32(uint256(hash) % MAX_DELAY_BLOCKS) + 1;
    }

    // Deposit with gas optimization
    function deposit(bytes32 _commitment) external payable {
        require(msg.value == FIXED_DEPOSIT, "Must send exact fixed deposit");
        Deposit storage dep = deposits[msg.sender];
        require(dep.commitment == bytes32(0), "Already deposited");

        uint32 delay = generateDelay(msg.sender);
        dep.commitment = _commitment;
        dep.depositBlock = uint32(block.number); // Safe downcast
        dep.delayBlocks = delay;
        dep.withdrawn = false;

        // Increment participantCount only if truly new
        if (participantCount < type(uint32).max) participantCount += 1;

        emit Deposited(_commitment);
    }

    // Withdraw with reentrancy protection and gas savings
    function withdraw(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input,
        address recipient
    ) external {
        require(participantCount >= minParticipantsව

        Deposit storage dep = deposits[msg.sender];
        require(dep.commitment != bytes32(0), "No deposit found");
        require(!dep.withdrawn, "Already withdrawn");
        require(block.number >= dep.depositBlock + dep.delayBlocks, "Delay not elapsed");

        bytes32 nullifierHash = bytes32(input[0]);
        require(!nullifiers[nullifierHash], "Nullifier already used");
        require(zkVerifier.verifyProof(a, b, c, input), "Invalid zk-SNARK proof");

        // Checks-Effects-Interactions: Update state first
        dep.withdrawn = true;
        nullifiers[nullifierHash] = true;

        // Interaction last: Send ETH
        (bool sent, ) = recipient.call{value: FIXED_DEPOSIT}("");
        require(sent, "Failed to send ETH");

        emit Withdrawn(recipient);
    }

    // Emergency withdraw with reentrancy protection
    function emergencyWithdraw() external {
        Deposit storage dep = deposits[msg.sender];
        require(dep.commitment != bytes32(0), "No deposit found");
        require(!dep.withdrawn, "Already withdrawn");
        require(block.number > dep.depositBlock + MAX_DELAY_BLOCKS * 2, "Too early");

        dep.withdrawn = true;
        (bool sent, ) = msg.sender.call{value: FIXED_DEPOSIT}("");
        require(sent, "Failed to send ETH");
    }

    receive() external payable {}
}
