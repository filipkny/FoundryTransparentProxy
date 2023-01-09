// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Implementation.sol";
import "../src/Proxy.sol";

contract ImplementationTest is Test {
    Implementation public implementation;
    ImplementationProxy public proxy;
    ImplementationProxyAdmin public proxyAdmin;

    address owner = vm.addr(1);
    address notOwner = vm.addr(2);

    bytes32 internal constant IMPL_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

    function checkAddressInImplSlot(address expected) internal {
        bytes32 proxySlot = vm.load(address(proxy), IMPL_SLOT);
        assertEq(proxySlot, bytes32(uint256(uint160(expected))));
    }

    function setUp() public {
        vm.startPrank(owner);

        // Deploy implementation implementation not behind proxy
        Implementation nonProxyImplementation = new Implementation();

        // Deploy proxy admin contract
        proxyAdmin = new ImplementationProxyAdmin();

        // Deploy proxy contract
        proxy = new ImplementationProxy(address(nonProxyImplementation), address(proxyAdmin), "");

        // Set what implementation deployment to use as implementation
        implementation = Implementation(proxyAdmin.getProxyImplementation(proxy));

        vm.stopPrank();
    }

    function testIncrement() public {
        implementation.increment();
        assertEq(implementation.number(), 1);
    }

    function testInitializable() external {
        assertFalse(implementation.initialized());

        vm.prank(owner);
        implementation.initialize(1);

        assertTrue(implementation.initialized());
        assertEq(implementation.number(), 1);
    }

    function testProxyImplSlot() external {
        checkAddressInImplSlot(address(implementation));
        assertEq(proxyAdmin.getProxyImplementation(proxy), address(implementation));
    }

    function testUpgrade() external {
        vm.startPrank(owner);

        Implementation currentImplementation = Implementation(proxyAdmin.getProxyImplementation(proxy));
        checkAddressInImplSlot(address(implementation));

        // First implementation increments number by 1
        currentImplementation.initialize(1);
        currentImplementation.increment();
        assertEq(currentImplementation.number(), 2);

        // Deploy a new implementation
        ImplementationV2 newImplementation = new ImplementationV2();
        
        // Upgrade proxy to new implementation
        proxyAdmin.upgrade(proxy, address(newImplementation));
        checkAddressInImplSlot(address(newImplementation));

        // New implementaiton increments number by 2
        currentImplementation = Implementation(proxyAdmin.getProxyImplementation(proxy));
        newImplementation.initialize(2);
        currentImplementation.increment();
        assertEq(currentImplementation.number(), 4);
    }
}
