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

    function testMakeReservation() public {
        vm.prank(deployer);
        welcomy.listApartment(
            bytes12("41.1618 N"),
            bytes12("8.5836 W"),
            10000000000000000
        );
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
        assertEq(
            welcomy.tokenURI(0),
            "data:application/json;base64,eyJuYW1lIjoiV2VsY29teSAjMCIsICJkZXNjcmlwdGlvbiI6IlRoYW5rIHlvdSBmb3IgY2hvb3NpbmcgdXMgZm9yIHlvdXIgcmVjZW50IHN0YXkuIFdlIGxvb2sgZm9yd2FyZCB0byB3ZWxjb21pbmcgeW91ISIsICJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEQ5NGJXd2dkbVZ5YzJsdmJqMGlNUzR3SWlCbGJtTnZaR2x1WnowaVZWUkdMVGdpUHo0OGMzWm5JSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRzFzYm5NNmVHeHBibXM5SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zaUlIWmxjbk5wYjI0OUlqRXVNU0lnZG1sbGQwSnZlRDBpTUNBd0lEUXdNQ0EwTURBaUlIQnlaWE5sY25abFFYTndaV04wVW1GMGFXODlJbmhOYVdSWlRXbGtJRzFsWlhRaVBqeHpkSGxzWlNCMGVYQmxQU0owWlhoMEwyTnpjeUkrUENGYlEwUkJWRUZiZEdWNGRDQjdJR1p2Ym5RdFptRnRhV3g1T2lCdGIyNXZjM0JoWTJVN0lHWnZiblF0YzJsNlpUb2dNakZ3ZUR0OVhWMCtQQzl6ZEhsc1pUNDhkR1Y0ZENCNFBTSTFKU0lnZVQwaU16VWxJajVYWld4amIyMTVJQ013UEM5MFpYaDBQangwWlhoMElIZzlJalVsSWlCNVBTSTBOU1VpUG1Gd1lYSjBiV1Z1ZEVsa09pQXdQQzkwWlhoMFBqeDBaWGgwSUhnOUlqVWxJaUI1UFNJMU5TVWlQbk4wWVhKME9pQXlNREl6TFRFdE1Ud3ZkR1Y0ZEQ0OGRHVjRkQ0I0UFNJMUpTSWdlVDBpTmpVbElqNWxibVE2SURJd01qTXRNUzB5UEM5MFpYaDBQand2YzNablBnPT0ifQ=="
        );
    }
}
