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
        require(_tokenAmount > 0, "Token amount must be greater than zero");
        require(_ethAmount > 0, "Ether amount must be greater than zero");

        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            // Use safeTransfer
            tokenInstance.transfer(_addresses[i], _tokenAmount);
            
            if (_addresses[i].balance == 0 && address(this).balance >= _ethAmount) {
                (bool sent, ) = payable(_addresses[i]).call{value: _ethAmount}("");
                require(sent, "Failed to send Ether");
            }
        }
        return true;
    }

    /**
     * @dev Sends tokens in batches to specified recipients.
     * @param _recipients Array of recipient addresses.
     * @param _values Array of token amounts corresponding to each recipient.
     * @return bool Whether the batch transfer was successful.
     */
    function sendBatch(address[] memory _recipients, uint256[] memory _values) onlyOwner public nonReentrant returns (bool) {
        require(_recipients.length == _values.length, "Recipients and values arrays must have the same length");
        for (uint i = 0; i < _values.length; i++) {
            require(_values[i] > 0, "Token value must be greater than zero");
            tokenInstance.transfer(_recipients[i], _values[i]);
        }
        return true;
    }

    /**
     * @dev Transfers all Ether in the contract to the owner.
     * @return bool Whether the transfer was successful.
     */
    function transferEthToOwner() onlyOwner public nonReentrant returns (bool) {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether to owner");
        return true;
    }

    /**
     * @dev Allows adding Ether to the contract.
     */
    receive() external payable {}

    /**
     * @dev Destroys the contract and transfers its balance to the owner.
     */
    function kill() onlyOwner public {
        selfdestruct(payable(owner()));
    }
}
