pragma solidity ^0.4.17;

import "./CNSSMinting.sol";

contract CNSSCore is CNSSMinting{
  
  address public newContractAddress;
  function GayCore() public {
    paused = true;
    etenalAddress = msg.sender;
    _creatGay(0, 0, 0, uint256(-1), address(0));
  }

  function setNewAddress(address _v2Address) external onlyEtenal whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
  }
  
  function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
  }

  function getGay(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
      Gay storage gay = gays[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (gay.siringWithId != 0);
        isReady = (gay.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(gay.cooldownIndex);
        nextActionAt = uint256(gay.cooldownEndBlock);
        siringWithId = uint256(gay.siringWithId);
        birthTime = uint256(gay.birthTime);
        matronId = uint256(gay.matronId);
        sireId = uint256(gay.sireId);
        generation = uint256(gay.generation);
        genes = gay.genes;
  }

  function unpause() public onlyEtenal whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
  }

  function withdrawBalance() external onlyEtenal {
        uint256 balance = this.balance;
        // Subtract all the currently pregnant kittens we have, plus 1 of margin.
        uint256 subtractFees = (pregnantGays + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }
}