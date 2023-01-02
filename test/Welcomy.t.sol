// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Welcomy.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
}

contract WelcomyTest is Test {
    Welcomy public welcomy;
    address public deployer;
    address public user;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        deployer = cheats.addr(1);
        user = cheats.addr(2);
        vm.deal(deployer, 1 ether);
        vm.deal(user, 1 ether);

        welcomy = new Welcomy();
    }

    function testListApartment() public {
        vm.prank(deployer);
        welcomy.listApartment("8.1618 N", "41.5836 W", 1000000000000000);
    }

    function testMakeReservation() public {
        vm.prank(deployer);
        welcomy.listApartment("41.1618 N", "8.5836 W", 10000000000000000);
        welcomy.listApartment("8.1618 N", "41.5836 W", 10000000000000000);
        vm.prank(user);
        assertEq(user.balance, 1000000000000000000);
        welcomy.makeReservation{value: 10000000000000000}(
            0,
            1,
            1,
            2023,
            2,
            1,
            2023
        );
        vm.prank(user);
        welcomy.makeReservation{value: 10000000000000000}(
            1,
            1,
            1,
            2023,
            2,
            1,
            2023
        );
        assertEq(welcomy.balanceOf(user), 1);
        assertEq(welcomy.ownerOf(0), user);
    }
}
