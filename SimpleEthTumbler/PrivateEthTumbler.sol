// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified interface for a pre-deployed zk-SNARK verifier contract
interface IZkVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external view returns (bool);
}

contract EnhancedEthTumbler {
    IZkVerifier public zkVerifier; // zk-SNARK verifier contract address
    uint256 public constant FIXED_DEPOSIT = 0.1 ether; // Fixed deposit amount for anonymity
    uint256 public constant MAX_DELAY_BLOCKS = 100; // Max delay in blocks (~25 minutes at 15s/block)
    uint256 public minParticipants = 3;
    uint256 public participantCount;

    struct Deposit {
        bytes32 commitment; // zk-SNARK commitment (hash of secret + nullifier)
        uint256 depositBlock; // Block number of deposit
        uint256 delayBlocks; // Random delay before withdrawal eligibility
        bool withdrawn;
    }

    mapping(address => Deposit) public deposits;
    mapping(bytes32 => bool) public nullifiers; // Prevent double-spending
    address[] public participants; // Track participants for withdrawal triggering

    event Deposited(address indexed sender, bytes32 commitment);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor(address _zkVerifier) {
        zkVerifier = IZkVerifier(_zkVerifier);
    }

    // Generate pseudo-random delay based on block data
    function generateDelay(address sender) internal view returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.number, sender));
        return (uint256(hash) % MAX_DELAY_BLOCKS) + 1; // 1 to MAX_DELAY_BLOCKS
    }

    // Deposit ETH with a zk-SNARK commitment
    function deposit(bytes32 _commitment) external payable {
        require(msg.value == FIXED_DEPOSIT, "Must send exact fixed deposit");
        require(deposits[msg.sender].commitment == bytes32(0), "Already deposited");

        uint256 delay = generateDelay(msg.sender);
        deposits[msg.sender] = Deposit({
            commitment: _commitment,
            depositBlock: block.number,
            delayBlocks: delay,
            withdrawn: false
        });
        participants.push(msg.sender);
        participantCount += 1;

        emit Deposited(msg.sender, _commitment);
    }

    // Withdraw using zk-SNARK proof
    function withdraw(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input, // [nullifierHash, recipientPublicKey]
        address recipient
    ) external {
        require(participantCount >= minParticipants, "Not enough participants");
        Deposit storage dep = deposits[msg.sender];
        require(dep.commitment != bytes32(0), "No deposit found");
        require(!dep.withdrawn, "Already withdrawn");
        require(block.number >= dep.depositBlock + dep.delayBlocks, "Delay not elapsed");

        bytes32 nullifierHash = bytes32(input[0]);
        require(!nullifiers[nullifierHash], "Nullifier already used");
        require(
            zkVerifier.verifyProof(a, b, c, input),
            "Invalid zk-SNARK proof"
        );

        // Mark as withdrawn and prevent double-spending
        dep.withdrawn = true;
        nullifiers[nullifierHash] = true;

        // Send ETH to recipient
        (bool sent, ) = recipient.call{value: FIXED_DEPOSIT}("");
        require(sent, "Failed to send ETH");

        emit Withdrawn(recipient, FIXED_DEPOSIT);
    }

    // Emergency cleanup (optional, for stuck funds after long delay)
    function emergencyWithdraw() external {
        Deposit storage dep = deposits[msg.sender];
        require(dep.commitment != bytes32(0), "No deposit found");
        require(!dep.withdrawn, "Already withdrawn");
        require(block.number > dep.depositBlock + MAX_DELAY_BLOCKS * 2, "Too early");

        dep.withdrawn = true;
        (bool sent, ) = msg.sender.call{value: FIXED_DEPOSIT}("");
        require(sent, "Failed to send ETH");
    }

    // Fallback to receive ETH
    receive() external payable {}
}
