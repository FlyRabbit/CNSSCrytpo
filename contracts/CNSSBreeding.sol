pragma solidity ^0.4.17;

import "./CNSSOwnership.sol";
import "./GeneScienceInterface.sol";

contract CNSSBreeding is CNSSOwnership {
  event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

  uint256 public autoBirthFee = 2 finney;
  uint256 public pregnantGays;

  GeneScienceInterface public geneScience;

  function setGeneScienceAddress(address _address) external onlyAdmin{
    GeneScienceInterface candidateContract = GeneScienceInterface(_address);

    require(candidateContract.isGeneScience());
    geneScience = candidateContract;
  }

  function _isReadyToBreed(Gay _gay) internal view returns (bool) {
    return (_gay.siringWithId == 0) && (_gay.cooldownEndBlock <= uint64(block.number));
  }

  function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
    address matronOwner = gayIndexToOwner[_matronId];
    address sireOwner = gayIndexToOwner[_sireId];
    return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
  }

  function _triggerCooldown(Gay storage _gay) internal{
    _gay.cooldownEndBlock = uint64((cooldowns[_gay.cooldownIndex]/secondsPerBlock).add(block.number));
    if (_gay.cooldownIndex < 13) {
      _gay.cooldownIndex = _gay.cooldownIndex.add(1);
    }
  }
  
  function approveSiring(address _addr, uint256 _sireId) external whenNotPaused {
    require(_owns(msg.sender, _sireId));
    sireAllowedToAddress[_sireId] = _addr;
  }

  function setAutoBirthFee(uint256 val) external onlyEtenal {
    autoBirthFee = val;
  }

  function _isReadyToGiveBirth(Gay _matron) private view returns (bool) {
    return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint(block.number));
  }

  function isReadyToBreed(uint256 _gayId) public view returns (bool){
    require(_gayId > 0);
    Gay storage gay = gays[_gayId];
    return _isReadyToBreed(gay);
  }

  function isPregnant(uint256 _gayId) public view returns (bool){
    require(_gayId > 0);
    return gays[_gayId].siringWithId != 0;
  }

  function _isValidMatingPair(Gay storage _matron, uint256 _matronId, Gay storage _sire, uint256 _sireId) private view returns (bool){
    if (_matronId == _sireId) {
      return false;
    }

    if (_matron.matronId == _sireId || _matron.sireId == _sireId){
      return false;
    }

    if (_sire.matronId == _matronId || _sire.sireId == _matronId){
      return false;
    }

    if (_sire.matronId == 0 || _matron.matronId == 0){
      return true;
    }

    if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId){
      return false;
    }

    if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId){
      return false;
    }

    return true;
  }

  function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)internal view returns (bool){
    Gay storage matron = gays[_matronId];
    Gay storage sire = gays[_sireId];
    return _isValidMatingPair(matron, _matronId, sire, _sireId);
  }

  function canBreedWith(uint256 _matronId, uint256 _sireId) external view returns(bool){
    require(_matronId > 0);
    require(_sireId > 0);
    Gay storage matron = gays[_matronId];
    Gay storage sire = gays[_sireId];
    return _isValidMatingPair(matron, _matronId, sire, _sireId) && _isSiringPermitted(_sireId, _matronId);
  }

  function _breedWith(uint256 _matronId, uint256 _sireId) internal {
    Gay storage sire = gays[_sireId];
    Gay storage matron = gays[_matronId];

    matron.siringWithId = uint32(_sireId);

    _triggerCooldown(sire);
    _triggerCooldown(matron);

    delete sireAllowedToAddress[_matronId];
    delete sireAllowedToAddress[_sireId];

    pregnantGays = pregnantGays.add(1);

    Pregnant(gayIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
  }

  function breedWithAuto(uint256 _matronId, uint256 _sireId) external payable whenNotPaused{
    require(msg.value >= autoBirthFee);
    require(_owns(msg.sender, _matronId));
    require(_isSiringPermitted(_sireId, _matronId));

    Gay storage matron = gays[_matronId];
    require(_isReadyToBreed(matron));

    Gay storage sire = gays[_sireId];
    require(_isReadyToBreed(sire));

    require(_isValidMatingPair(matron, _matronId, sire, _sireId));
    _breedWith(_matronId, _sireId);
  }

  function giveBirth(uint256 _matronId) external whenNotPaused returns (uint256){
    Gay storage matron = gays[_matronId];
    require(matron.birthTime != 0);
    require(_isReadyToGiveBirth(matron));

    uint256 sireId = matron.siringWithId;
    Gay storage sire = gays[sireId];

    uint256 parentGen = matron.generation;
    if (sire.generation > matron.generation) {
      parentGen = sire.generation;
    }

    uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);
    address owner = gayIndexToOwner[_matronId];
    uint256 gayenId = _createGay(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

    delete matron.siringWithId;
    pregnantGays =  pregnantGays.sub(1);

    msg.sender.send(autoBirthFee);
    return gayenId;
  }
}