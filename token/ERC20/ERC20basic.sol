// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * @title ERC20Basic
 * @dev Fundamental function set for ERC20 interface. See also https://github.com/ethereum/EIPs/issues/179
 * @dev To be called with most every SC
 */

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
