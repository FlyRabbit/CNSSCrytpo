pragma solidity ^0.4.17;

import "./CNSSAuction.sol";

contract CNSSMinting is CNSSAuction{
  // Limits the number of cats the contract owner can ever create.
  uint256 public constant PROMO_CREATION_LIMIT = 5000;
  uint256 public constant GEN0_CREATION_LIMIT = 45000;

  // Constants for gen0 auctions.
  uint256 public constant GEN0_STARTING_PRICE = 10 finney;
  uint256 public constant GEN0_AUCTION_DURATION = 1 days;

  // Counts the number of cats the contract owner has created.
  uint256 public promoCreatedCount;
  uint256 public gen0CreatedCount;

  function createPromoGay(uint256 _genes, address _owner) external onlyEtenal{
    address gayOwner = _owner;
    if (gayOwner == address(0)) {
          gayOwner = cooAddress;
    }
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    promoCreatedCount++;
    _createGay(0, 0, 0, _genes, gayOwner);
  }

  function createGen0Auction(uint256 _genes) external onlyEtenal {
      require(gen0CreatedCount < GEN0_CREATION_LIMIT);

      uint256 gayId = _createGay(0, 0, 0, _genes, address(this));
      _approve(gayId, saleAuction);

      saleAuction.createAuction(
          gayId,
          _computeNextGen0Price(),
          0,
          GEN0_AUCTION_DURATION,
          address(this)
      );

      gen0CreatedCount++;
  }

  function _computeNextGen0Price() internal view returns (uint256) {
      uint256 avePrice = saleAuction.averageGen0SalePrice();

      // Sanity check to ensure we don't overflow arithmetic
      require(avePrice == uint256(uint128(avePrice)));

      uint256 nextPrice = avePrice + (avePrice / 2);

      // We never auction for less than starting price
      if (nextPrice < GEN0_STARTING_PRICE) {
          nextPrice = GEN0_STARTING_PRICE;
      }

      return nextPrice;
  }
}