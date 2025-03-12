pragma solidity ^0.8.0;

/**
 * @title AirDrop
 * @dev Updated version of AirDrop
 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/access/Ownable.sol";

contract Token is ERC20 {
    // Use ERC20 from OpenZeppelin for safe transfers
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to which ownership is transferred.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract AirDrop is Ownable {
    Token public tokenInstance;

  /*
    constructor function to set token address
   */
    constructor(address _tokenAddress) {
        tokenInstance = Token(_tokenAddress);
    }

  /*
    Airdrop function which takes up an array of address, single token amount, and eth amount and calls the
    transfer function to send the token plus send eth to the address if balance is 0
   */

bool private locked;

modifier noReentrancy() {
    require(!locked, "Reentrancy attack detected");
    locked = true;
    _;
    locked = false;
}

    function doAirDrop(address[] memory _address, uint256 _amount, uint256 _ethAmount) onlyOwner public returns (bool) {
        uint256 count = _address.length;
        for (uint256 i = 0; i < count; i++) {
            // Use safeTransfer
            tokenInstance.transfer(_address[i], _amount);
            
            if (_address[i].balance == 0 && this.balance >= _ethAmount) {
                (bool sent, ) = payable(_address[i]).call{value: _ethAmount}("");
                require(sent, "Failed to send Ether");
            }
        }
        return true;
    }

    function sendBatch(address[] memory _recipients, uint256[] memory _values) onlyOwner public returns (bool) {
        require(_recipients.length == _values.length);
        for (uint i = 0; i < _values.length; i++) {
            tokenInstance.transfer(_recipients[i], _values[i]);
        }
        return true;
    }

  function transferEthToOnwer() onlyOwner public returns (bool) {
    require(owner.send(this.balance));
  }

  /*
    function to add eth to the contract
   */
  function() payable {

  }

  /*
    function to kill contract
  */

  function kill() onlyOwner {
    selfdestruct(owner);
  }
}
