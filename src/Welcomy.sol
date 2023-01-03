// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract Welcomy is ERC721URIStorage {
    struct Apartment {
        uint256 pricePerNight; // in wei
        bytes12 latitude;
        bytes12 longitude;
        address owner;
    }

    Apartment[] public apartments;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => mapping(uint256 => bool))
        public apartmentUnavailableDates;
    mapping(address => uint256) public unclaimedEth;

    event NewApartment(uint256 apartmentId);

    event NewReservation(address owner, uint256 reservationId);

    event NewRating(uint256 reservationId, uint8 rating, string message);

    modifier onlyApartmentOwner(uint256 apartmentId) {
        require(
            apartments[apartmentId].owner == msg.sender,
            "Not the apartment owner"
        );
        _;
    }

    constructor() ERC721("Welcomy", "WELC") {}

    function listApartment(
        bytes12 _latitude,
        bytes12 _longitude,
        uint256 _pricePerNight
    ) external {
        apartments.push(
            Apartment(_pricePerNight, _latitude, _longitude, msg.sender)
        );

        emit NewApartment(apartments.length - 1);
    }

    function changeApartmentOwnership(
        uint256 _apartmentId,
        address _newOwner
    ) external onlyApartmentOwner(_apartmentId) {
        apartments[_apartmentId].owner = _newOwner;
    }

    function changeApartmentPrice(
        uint256 _apartmentId,
        uint256 _newPrice
    ) external onlyApartmentOwner(_apartmentId) {
        apartments[_apartmentId].pricePerNight = _newPrice;
    }

    function makeReservation(
        uint256 _apartmentId,
        uint256 _dayStart,
        uint256 _monthStart,
        uint256 _yearStart,
        uint256 _dayEnd,
        uint256 _monthEnd,
        uint16 _yearEnd
    ) external payable {
        require(_apartmentId < apartments.length, "Invalid apartment");

        uint256 start = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            _yearStart,
            _monthStart,
            _dayStart
        );

        uint256 end = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            _yearEnd,
            _monthEnd,
            _dayEnd
        );

        require(
            start >= formatDate(block.timestamp) && end > start,
            "Invalid date"
        );

        uint256 daysCount = (end - start) / 60 / 60 / 24;
        uint256[] memory datesInBetween = getReservationDates(start, daysCount);
        require(
            checkAvailability(_apartmentId, datesInBetween),
            "Unavailable dates"
        );

        require(
            msg.value == apartments[_apartmentId].pricePerNight * daysCount,
            "Invalid amount"
        );
        unclaimedEth[apartments[_apartmentId].owner] += msg.value;

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);

        addUnavailableDates(_apartmentId, datesInBetween);

        string memory _tokenURI = formatTokenURI(
            tokenId,
            _apartmentId,
            _dayStart,
            _monthStart,
            _yearStart,
            _dayEnd,
            _monthEnd,
            _yearEnd
        );
        _setTokenURI(tokenId, _tokenURI);

        _tokenIds.increment();

        emit NewReservation(msg.sender, tokenId);
    }

    function rateStay(
        uint256 _reservationId,
        uint8 _rating,
        string calldata _message
    ) external {
        require(_exists(_reservationId), "Invalid reservation");
        require(msg.sender == ownerOf(_reservationId), "You are not the owner");
        require(_rating < 11, "Invalid rating");

        _burn(_reservationId);

        emit NewRating(_reservationId, _rating, _message);
    }

    function withdrawMoney(uint256 _amount) public {
        require(unclaimedEth[msg.sender] >= _amount, "Invalid amount");
        unclaimedEth[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getReservationDates(
        uint256 _startDate,
        uint256 _daysCount
    ) internal pure returns (uint256[] memory) {
        uint256[] memory reservationDates = new uint256[](_daysCount);

        for (uint i = 0; i < _daysCount; ++i) {
            reservationDates[i] = _startDate;
            _startDate += 1 days;
        }

        return reservationDates;
    }

    function addUnavailableDates(
        uint _apartmentId,
        uint256[] memory _datesInBetween
    ) private {
        for (uint i = 0; i < _datesInBetween.length; ++i) {
            apartmentUnavailableDates[_apartmentId][_datesInBetween[i]] = true;
        }
    }

    function checkAvailability(
        uint _apartmentId,
        uint256[] memory _datesInBetween
    ) private view returns (bool) {
        for (uint i = 0; i < _datesInBetween.length; ++i) {
            if (apartmentUnavailableDates[_apartmentId][_datesInBetween[i]]) {
                return false;
            }
        }
        return true;
    }

    // Format timestamp "YYYY:MM:DD HH:MM:SS" to "YYYY:MM:DD"
    function formatDate(uint256 timestamp) private pure returns (uint256) {
        return
            BokkyPooBahsDateTimeLibrary.timestampFromDate(
                BokkyPooBahsDateTimeLibrary.getYear(timestamp),
                BokkyPooBahsDateTimeLibrary.getMonth(timestamp),
                BokkyPooBahsDateTimeLibrary.getDay(timestamp)
            );
    }

    function formatTokenURI(
        uint256 _tokenId,
        uint256 _apartmentId,
        uint256 _dayStart,
        uint256 _monthStart,
        uint256 _yearStart,
        uint256 _dayEnd,
        uint256 _monthEnd,
        uint256 _yearEnd
    ) private pure returns (string memory) {
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;}]]></style>',
                        '<text x="5%" y="35%">Welcomy #',
                        Strings.toString(_tokenId),
                        "</text>",
                        '<text x="5%" y="45%">apartmentId: ',
                        Strings.toString(_apartmentId),
                        "</text>",
                        '<text x="5%" y="55%">start: ',
                        Strings.toString(_yearStart),
                        "-",
                        Strings.toString(_monthStart),
                        "-",
                        Strings.toString(_dayStart),
                        "</text>",
                        '<text x="5%" y="65%">end: ',
                        Strings.toString(_yearEnd),
                        "-",
                        Strings.toString(_monthEnd),
                        "-",
                        Strings.toString(_dayEnd),
                        "</text>",
                        "</svg>"
                    )
                )
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Welcomy #',
                                Strings.toString(_tokenId),
                                '", "description":"Thank you for choosing us for your recent stay. We look forward to welcoming you!", "image":"',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
