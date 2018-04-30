pragma solidity ^0.4.17;

contract CNSSAccessControl {

  event ContractUpgrade(address newContract);

  address public etenalAddress;

  bool public paused = false;

  modifier onlyAdmin() {
    require(
      msg.sender == etenalAddress
    );
    _;
  }

  modifier onlyEtenal() {
    require(msg.sender == etenalAddress);
    _;
  }

  function setEtenal(address _etenalAddress) external onlyEtenal{
    require(_etenalAddress != address(0));

    etenalAddress = _etenalAddress;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() external onlyEtenal whenNotPaused {
    paused = true;
  }

  function unpause() public onlyEtenal whenPaused {
    paused = false;
  }
}