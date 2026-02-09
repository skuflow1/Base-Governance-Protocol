// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovToken is ERC20Votes, Ownable {
    constructor() ERC20("BaseGovToken", "BGT") EIP712("BaseGovToken", "1") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // required overrides
    function _update(address from, address to, uint256 value) internal override(ERC20Votes) {
        super._update(from, to, value);
    }
}
