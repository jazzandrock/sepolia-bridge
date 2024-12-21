// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is ERC20, ERC20Permit, AccessControl {
    bool public mintableByAnyone = true;
    bytes32 public constant MINTER_ROLE = keccak256("minter");

    constructor(string memory name)
        ERC20(name, name)
        ERC20Permit(name)
    {}

    function mint(address to, uint256 amount) public {
        require(mintableByAnyone || hasRole(MINTER_ROLE, msg.sender), "can't mint");
        _mint(to, amount);
    }
}
