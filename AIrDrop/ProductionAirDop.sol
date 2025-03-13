pragma solidity ^0.8.0;

/**
 * @title AirDrop
 * @dev Updated version of AirDrop contract with enhanced security and functionality.
 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/security/ReentrancyGuard.sol";

contract Token is ERC20 {
    // Use ERC20 from OpenZeppelin for safe transfers
}

/**
 * @dev The transferOwnership function is inherited from OpenZepplin’s Ownable contract, allowing the owner to transfer ownership to a new address.
 */

contract AirDrop is Ownable, ReentrancyGuard {
    Token public tokenInstance;
}

    /**
     * @dev Performs an airdrop of tokens to specified addresses.
     * @param _addresses Array of recipient addresses.
     * @param _tokenAmount Amount of tokens to transfer to each address.
     * @param _ethAmount Amount of Ether to transfer if the recipient's balance is zero.
     * @return bool Whether the airdrop was successful.
     */
    function doAirDrop(address[] memory _addresses, uint256 _tokenAmount, uint256 _ethAmount) onlyOwner public nonReentrant returns (bool) {
        require(_addresses.length > 0, "Addresses array cannot be empty");
