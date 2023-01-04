// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Welcomy.sol";
import "../src/BokkyPooBahsDateTimeLibrary.sol";

interface CheatCodes {
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);

    function warp(uint256) external;
}

contract WelcomyTest is Test {
    Welcomy public welcomy;
    address public user;
    address public user2;
    address public user3;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        user = cheats.addr(1);
        user2 = cheats.addr(2);
        user3 = cheats.addr(3);
        vm.deal(user, 1.01 ether);
        vm.deal(user2, 0.99 ether);

        welcomy = new Welcomy();

        // list 1 apartment -> apartmentId = 0
        vm.prank(user2);
        welcomy.listApartment("8.5836 W", "41.1618 N", 0.01 ether);

        // set block.timestamp to -> 3 Jan 2023
        vm.warp(1672772953);

        // make 1 reservation -> tokenId = 0
        vm.prank(user);
        welcomy.makeReservation{value: 0.01 ether}(0, 3, 1, 2023, 4, 1, 2023);

        assertEq(welcomy.unclaimedEth(user2), 0.01 ether);

        vm.prank(user2);
        welcomy.withdraw(0.01 ether);

        assertEq(user.balance, 1 ether);
        assertEq(user2.balance, 1 ether);
        assertEq(welcomy.unclaimedEth(user2), 0);
    }

    function test_listApartment() public {
        vm.prank(user2);
        welcomy.listApartment(
            bytes16("41.1618 N"),
            bytes16("8.5836 W"),
            0.001 ether
        );
        (uint256 apartmentPrice, address apartmentOwner) = welcomy.apartments(1);
        assertEq(apartmentOwner, user2);
        assertEq(apartmentPrice, 0.001 ether);
    }

    function test_changeApartmentOwnership() public {
        (, address owner) = welcomy.apartments(0);
        assertEq(owner, user2);

        vm.prank(user2);
        welcomy.changeApartmentOwnership(0, user);

        (, address newOwner) = welcomy.apartments(0);
        assertEq(newOwner, user);
    }

    function testCannot_changeApartmentOwnership_notOwner() public {
        (, address owner) = welcomy.apartments(0);
        assertEq(owner, user2);

        vm.prank(user);
        vm.expectRevert("Not the apartment owner");
        welcomy.changeApartmentOwnership(0, user3);
    }

    function test_changeApartmentPrice() public {
        (uint256 price, ) = welcomy.apartments(0);
        assertEq(price, 0.01 ether);

        vm.prank(user2);
        welcomy.changeApartmentPrice(0, 0.02 ether);

        (uint256 newPrice, ) = welcomy.apartments(0);
        assertEq(newPrice, 0.02 ether);
    }

    function testCannot_changeApartmentPrice_notOwner() public {
        (uint256 price, ) = welcomy.apartments(0);
        assertEq(price, 0.01 ether);

        vm.prank(user);
        vm.expectRevert("Not the apartment owner");
        welcomy.changeApartmentPrice(0, 0.03 ether);
    }

    function test_makeReservation() public {
        assertEq(user.balance, 1 ether);
        assertEq(user2.balance, 1 ether);

        vm.prank(user);
        welcomy.makeReservation{value: 0.01 ether}(0, 1, 2, 2023, 2, 2, 2023);
        
        assertEq(user.balance, 1 ether - 0.01 ether);
        assertEq(welcomy.unclaimedEth(user), 0);
        assertEq(welcomy.unclaimedEth(user2), 0.01 ether);
        assertEq(
            welcomy.tokenURI(1),
            "data:application/json;base64,eyJuYW1lIjoiV2VsY29teSAjMSIsICJkZXNjcmlwdGlvbiI6IlRoYW5rIHlvdSBmb3IgY2hvb3NpbmcgdXMgZm9yIHlvdXIgcmVjZW50IHN0YXkuIFdlIGxvb2sgZm9yd2FyZCB0byB3ZWxjb21pbmcgeW91ISIsICJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEQ5NGJXd2dkbVZ5YzJsdmJqMGlNUzR3SWlCbGJtTnZaR2x1WnowaVZWUkdMVGdpUHo0OGMzWm5JSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRzFzYm5NNmVHeHBibXM5SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zaUlIWmxjbk5wYjI0OUlqRXVNU0lnZG1sbGQwSnZlRDBpTUNBd0lEUXdNQ0EwTURBaUlIQnlaWE5sY25abFFYTndaV04wVW1GMGFXODlJbmhOYVdSWlRXbGtJRzFsWlhRaVBqeHpkSGxzWlNCMGVYQmxQU0owWlhoMEwyTnpjeUkrUENGYlEwUkJWRUZiZEdWNGRDQjdJR1p2Ym5RdFptRnRhV3g1T2lCdGIyNXZjM0JoWTJVN0lHWnZiblF0YzJsNlpUb2dNakZ3ZUR0OVhWMCtQQzl6ZEhsc1pUNDhkR1Y0ZENCNFBTSTFKU0lnZVQwaU16VWxJajVYWld4amIyMTVJQ014UEM5MFpYaDBQangwWlhoMElIZzlJalVsSWlCNVBTSTBOU1VpUG1Gd1lYSjBiV1Z1ZEVsa09pQXdQQzkwWlhoMFBqeDBaWGgwSUhnOUlqVWxJaUI1UFNJMU5TVWlQbk4wWVhKME9pQXlNREl6TFRJdE1Ud3ZkR1Y0ZEQ0OGRHVjRkQ0I0UFNJMUpTSWdlVDBpTmpVbElqNWxibVE2SURJd01qTXRNaTB5UEM5MFpYaDBQand2YzNablBnPT0ifQ=="
        );
        assertEq(welcomy.ownerOf(1), user);
        assertEq(
            welcomy.apartmentUnavailableDates(
                0,
                BokkyPooBahsDateTimeLibrary.timestampFromDate(2023, 2, 1)
            ),
            true
        );
        assertEq(
            welcomy.apartmentUnavailableDates(
                0,
                BokkyPooBahsDateTimeLibrary.timestampFromDate(2023, 2, 2)
            ),
            false
        );
    }

    function testCannot_makeReservation_invalidDates() public {
        vm.prank(user);
        vm.expectRevert("Invalid date");
        welcomy.makeReservation{value: 0.1 ether}(0, 29, 2, 2024, 30, 2, 2024); // nonexistent day (february)
        vm.expectRevert("Invalid date");
        welcomy.makeReservation{value: 0.1 ether}(0, 1, 13, 2024, 2, 13, 2024); // invalid month
        vm.expectRevert("Invalid date");
        welcomy.makeReservation{value: 0.1 ether}(0, 112, 1, 2024, 113, 1, 2024); // invalid day
        vm.expectRevert("Dates are incorrect");
        welcomy.makeReservation{value: 0.1 ether}(0, 1, 1, 2024, 1, 1, 2024); // same day
        vm.expectRevert("Dates are incorrect");
        welcomy.makeReservation{value: 0.1 ether}(0, 2, 1, 2024, 1, 1, 2024); // start > end
        vm.expectRevert("Dates are incorrect");
        welcomy.makeReservation{value: 0.1 ether}(0, 1, 1, 2023, 2, 1, 2023); // past date
    }

    function testCannot_makeReservation_unavailableDates() public {
        vm.prank(user);
        vm.expectRevert("Unavailable dates");
        welcomy.makeReservation{value: 0.02 ether}(0, 3, 1, 2023, 5, 1, 2023);

        assertEq(
            welcomy.apartmentUnavailableDates(
                0,
                BokkyPooBahsDateTimeLibrary.timestampFromDate(2023, 1, 4)
            ),
            false
        );
    }

    function testCannot_makeReservation_wrongMsgValue() public {
        vm.prank(user);
        vm.expectRevert("Invalid amount");
        welcomy.makeReservation{value: 0.00999 ether}(0, 1, 1, 2024, 2, 1, 2024);

        vm.expectRevert("ERC721: invalid token ID");
        welcomy.tokenURI(1);
    }

    function test_makeReservation_afterChangingApartmentOwner() public {
        vm.prank(user);
        welcomy.makeReservation{value: 0.01 ether}(0, 1, 1, 2024, 2, 1, 2024);

        assertEq(welcomy.unclaimedEth(user2), 0.01 ether);
        assertEq(welcomy.unclaimedEth(user3), 0);
        
        (, address owner) = welcomy.apartments(0);
        assertEq(owner, user2);

        vm.prank(user2);
        welcomy.changeApartmentOwnership(0, user3);

        vm.prank(user);
        welcomy.makeReservation{value: 0.02 ether}(0, 2, 1, 2024, 4, 1, 2024);

        assertEq(welcomy.unclaimedEth(user2), 0.01 ether);
        assertEq(welcomy.unclaimedEth(user3), 0.02 ether);

        (, address newOwner) = welcomy.apartments(0);
        assertEq(newOwner, user3);
    }

    function test_makeReservation_afterChangingApartmentPrice() public {
        assertEq(welcomy.unclaimedEth(user2), 0);

        vm.prank(user);
        welcomy.makeReservation{value: 0.01 ether}(0, 1, 1, 2024, 2, 1, 2024);

        assertEq(welcomy.unclaimedEth(user2), 0.01 ether);
        
        (uint256 price, ) = welcomy.apartments(0);
        assertEq(price, 0.01 ether);

        vm.prank(user2);
        welcomy.changeApartmentPrice(0, 0.02 ether);

        vm.prank(user);
        welcomy.makeReservation{value: 0.04 ether}(0, 2, 1, 2024, 4, 1, 2024); // 2 nights -> msg.value: 0.02 * 2 = 0.04 ether

        assertEq(welcomy.unclaimedEth(user2), 0.05 ether);

        (uint256 newPrice, ) = welcomy.apartments(0);
        assertEq(newPrice, 0.02 ether);
    }

    function test_rateStay() public {
        assertEq(welcomy.ownerOf(0), user);

        vm.prank(user);
        welcomy.rateStay(0, 10, "Loved everything about it. Thanks a lot!");
    }

    function testCannot_rateStay_invalidArguments() public {
        vm.prank(user2);
        vm.expectRevert("You are not the owner");
        welcomy.rateStay(0, 10, "Loved everything about it. Thanks a lot!");

        vm.prank(user);
        vm.expectRevert("Invalid reservation");
        welcomy.rateStay(1, 10, "Loved everything about it. Thanks a lot!");

        vm.prank(user);
        vm.expectRevert("Invalid rating");
        welcomy.rateStay(0, 11, "Loved everything about it. Thanks a lot!");
    }
}
