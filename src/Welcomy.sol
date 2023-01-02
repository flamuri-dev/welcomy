// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract Welcomy is ERC721URIStorage {
    struct Coordinates {
        string latitude;
        string longitude;
    }

    struct Apartment {
        uint256 pricePerNight; // in wei
        Coordinates coordinates;
        address owner;
    }

    struct Reservation {
        uint256 apartmentId;
        uint256 start;
        uint256 end;
    }

    struct Rating {
        uint256 reservationId;
        uint256 timestamp;
        uint8 rating; // 0 to 10
    }

    Apartment[] public apartments;
    Reservation[] public reservations;
    Rating[] public ratings;

    mapping(uint256 => mapping(uint256 => bool)) public apartmentUnavailableDates;
    mapping(address => uint256) public unclaimedEth;

    event NewApartment(uint256 apartmentId, string latitude, string longitude);

    event NewReservation(
        address owner,
        uint256 reservationId
    );

    event NewRating(
        uint256 ratingId,
        string message
    );

    modifier onlyApartmentOwner(uint256 apartmentId) {
        require(
            apartments[apartmentId].owner == msg.sender,
            "Not the apartment owner"
        );
        _;
    }

    constructor() ERC721("Welcomy", "WELC") {}

    function listApartment(
        string calldata _latitude,
        string calldata _longitude,
        uint256 _pricePerNight
    ) external {
        apartments.push(
            Apartment(
                _pricePerNight,
                Coordinates(_latitude, _longitude),
                msg.sender
            )
        );
        emit NewApartment(apartments.length - 1, _latitude, _longitude);
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
        uint256 _yearEnd
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

        uint256 tokenId = reservations.length;
        _safeMint(msg.sender, tokenId);

        addUnavailableDates(_apartmentId, datesInBetween);

        reservations.push(Reservation(_apartmentId, start, end));

        string memory _tokenURI = formatTokenURI(tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit NewReservation(msg.sender, tokenId);
    }

    function rateStay( 
        uint256 _reservationId,
        uint8 _rating,
        string calldata _message
    ) external {
        require(_reservationId < reservations.length, "Invalid reservation");
        require(msg.sender == ownerOf(_reservationId), "You are not the owner");
        require(reservations[_reservationId].end <= formatDate(block.timestamp));
        require(_rating < 11, "Invalid rating");

        ratings.push(Rating(_reservationId, block.timestamp, _rating));
        _burn(_reservationId);

        emit NewRating(ratings.length - 1, _message);
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
        uint256 _tokenId
    ) private view returns (string memory) {
        uint256 apartmentId = reservations[_tokenId].apartmentId;

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;}]]></style>',
                        '<text x="5%" y="25%">Welcomy #',
                        Strings.toString(_tokenId),
                        "</text>",
                        '<text x="5%" y="35%">apartmentId: ',
                        Strings.toString(apartmentId),
                        "</text>",
                        '<text x="5%" y="45%">latitude: ',
                        apartments[apartmentId].coordinates.latitude,
                        "</text>",
                        '<text x="5%" y="55%">longitude: ',
                        apartments[apartmentId].coordinates.longitude,
                        "</text>",
                        '<text x="5%" y="65%">start: ',
                        Strings.toString(reservations[_tokenId].start),
                        "</text>",
                        '<text x="5%" y="75%">end: ',
                        Strings.toString(reservations[_tokenId].end),
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
