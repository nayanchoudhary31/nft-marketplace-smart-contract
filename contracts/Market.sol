// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./IERC721.sol";

contract Market {
    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }
    struct ListingDetails {
        ListingStatus status;
        address seller;
        address token;
        uint256 tokenId;
        uint256 price;
    }

    mapping(uint256 => ListingDetails) private _listingDetails;

    uint256 private _listingId = 0;

    event ListingToken(
        uint256 listingId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    event SaleToken(
        uint256 listingId,
        address buyer,
        address token,
        uint256 tokenId,
        uint256 price
    );

    event CancelListing(uint256 listingId, address seller);

    function listToken(
        address _token,
        uint256 _tokenId,
        uint256 _price
    ) external {
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        ListingDetails memory listdetails = ListingDetails(
            ListingStatus.Active,
            msg.sender,
            _token,
            _tokenId,
            _price
        );

        _listingId++;
        _listingDetails[_listingId] = listdetails;

        emit ListingToken(_listingId, msg.sender, _token, _tokenId, _price);
    }

    function buyToken(uint256 listId) external payable {
        ListingDetails storage listing = _listingDetails[listId];
        require(msg.sender != listing.seller, "Seller can't be Buyer");
        require(listing.status == ListingStatus.Active, "Listing Not Active");
        require(msg.value >= listing.price, "Insufficient amount");

        IERC721(listing.token).safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
        payable(listing.seller).transfer(listing.price);

        emit SaleToken(
            listId,
            msg.sender,
            listing.token,
            listing.tokenId,
            listing.price
        );
    }

    function cancelListing(uint256 _listId) public {
        ListingDetails storage listing = _listingDetails[_listId];
        require(msg.sender == listing.seller, "Only Seller Can Cancel");
        require(listing.status == ListingStatus.Active, "Listing Not Active");
        listing.status = ListingStatus.Cancelled;

        IERC721(listing.token).safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        emit CancelListing(_listId, msg.sender);
    }

    function getListingDetails(uint256 _listId)
        public
        view
        returns (ListingDetails memory)
    {
        return _listingDetails[_listId];
    }
}
