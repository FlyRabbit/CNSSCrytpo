pragma solidity ^0.4.17;

import "./CNSSAccessControl.sol";
import "./ClockAuction/ClockAuction.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./ClockAuction/SaleClockAuction.sol";
import "./ClockAuction/SiringClockAuction.sol";


contract CNSSBase is CNSSAccessControl {

  using SafeMath for uint256;
  using SafeMath32 for uint32;
  using SafeMath16 for uint16;


  event Birth(address owner, uint256 gayId, uint256 matronId, uint256 sireId, uint256 genes);

  event Transfer(address from, address to, uint256 tokenId);

  struct Gay{
    uint256 genes;
    uint64 birthTime;
    uint64 cooldownEndBlock;
    uint32 matronId;
    uint32 sireId;
    uint32 siringWithId;
    uint16 cooldownIndex;
    uint16 generation;
  }

  uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
  ];

  uint256 public secondsPerBlock = 15;
  uint256 newGayId;

  Gay[] gays;

  mapping (uint256 => address) public gayIndexToOwner;
  mapping (address => uint256) public ownershipTokenCount;
  mapping (uint256 => address) public gayIndexToApproved;
  mapping (uint256 => address) public sireAllowedToAddress;

  SaleClockAuction public saleAuction;
  SiringClockAuction public siringAuction;

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
    gayIndexToOwner[_tokenId] = _to;
    
    if (_from != address(0)){
      ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
      delete gayIndexToApproved[_tokenId];
      delete sireAllowedToAddress[_tokenId];
    }

    emit Transfer(_from, _to, _tokenId);
  }

  function _createGay(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
  )internal returns (uint256) {
    require(_matronId == uint256(uint32(_matronId)));
    require(_sireId == uint256(uint32(_sireId)));
    require(_generation == uint256(uint16(_generation)));

    uint16 cooldownIndex = uint16(_generation.div(2));
    if (cooldownIndex > 13){
      cooldownIndex = 13;
    }

    Gay memory _gay = Gay({
      genes: _genes,
      birthTime: uint64(now),
      cooldownEndBlock: 0,
      matronId: uint32(_matronId),
      sireId: uint32(_sireId),
      siringWithId: 0,
      cooldownIndex: cooldownIndex,
      generation: uint16(_generation)
    });

    newGayId = gays.push(_gay) - 1;

    require(newGayId == uint256(uint32(newGayId)));

    emit Birth(_owner, newGayId, uint256(_gay.matronId), uint256(_gay.sireId), _gay.genes);

    _transfer(0, _owner, newGayId);

    return newGayId;
  }

  function setSecondsPerBlock(uint256 secs) external onlyAdmin {
    require(secs < cooldowns[0]);
    secondsPerBlock = secs;
  }
}