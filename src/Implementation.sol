// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";


contract Implementation is OwnableUpgradeable {
    uint256 public number;
    bool public initialized = false;

    function initialize(uint256 newNumber) public initializer {
        __Ownable_init();
        number = newNumber;
        initialized = true;
    }

    function increment() virtual public {
        number++;
    }
}

contract ImplementationV2 is Implementation{
    function increment() public override {
        number += 2;
    }
}