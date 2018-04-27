pragma solidity ^0.4.17;

import "./CNSSBreeding.sol";

contract CNSSAuction is CNSSBreeding {

  function setSaleAuctionAddress(address _address) external onlyEtenal {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
  }

  function setSiringAuctionAddress(address _address) external onlyEtenal {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
  }

  function createSaleAuction(
        uint256 _gayId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {

        require(_owns(msg.sender, _gayId));

        require(!isPregnant(_gayId));
        _approve(_gayId, saleAuction);

        saleAuction.createAuction(
            _gayId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


    function createSiringAuction(
        uint256 _gayId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _gayId));
        require(isReadyToBreed(_gayId));
        _approve(_gayId, siringAuction);

        siringAuction.createAuction(
            _gayId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        // Define the current price of the auction.
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    function withdrawAuctionBalances() external onlyAdmin {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}