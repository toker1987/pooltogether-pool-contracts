pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";

import "../utils/ExtendedSafeCast.sol";
import "../prize-pool/MappedSinglyLinkedList.sol";
import "./VolumeDrip.sol";

library VolumeDripManager {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using ExtendedSafeCast for uint256;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using VolumeDrip for VolumeDrip.State;

  struct State {
    mapping(address => MappedSinglyLinkedList.Mapping) dripTokens;
    mapping(address => mapping(address => VolumeDrip.State)) volumeDrips;
  }

  function addDrip(
    State storage self,
    address measure,
    address dripToken,
    uint32 periodBlocks,
    uint128 dripRatePerBlock,
    uint32 currentBlockNumber
  )
    internal
  {
    require(!self.dripTokens[measure].contains(dripToken), "VolumeDripManager/drip-exists");
    if (self.dripTokens[measure].count == 0) {
      address[] memory single = new address[](1);
      single[0] = dripToken;
      self.dripTokens[measure].initialize(single);
    } else {
      self.dripTokens[measure].addAddress(dripToken);
    }
    self.volumeDrips[measure][dripToken].initialize(periodBlocks, dripRatePerBlock, currentBlockNumber);
  }

  function removeDrip(
    State storage self,
    address measure,
    address prevDripToken,
    address dripToken
  )
    internal
  {
    delete self.volumeDrips[measure][dripToken];
    self.dripTokens[measure].removeAddress(prevDripToken, dripToken);
  }

  function setDripRate(State storage self, address measure, address dripToken, uint128 dripRatePerBlock) internal {
    require(self.dripTokens[measure].contains(dripToken), "DripManager/drip-not-exists");
    self.volumeDrips[measure][dripToken].dripRatePerBlock = dripRatePerBlock;
  }

  function deposit(
    State storage self,
    address measure,
    address user,
    uint256 amount,
    uint256 currentBlockNumber
  )
    internal
  {
    address currentDripToken = self.dripTokens[measure].addressMap[MappedSinglyLinkedList.SENTINAL_TOKEN];
    while (currentDripToken != address(0) && currentDripToken != MappedSinglyLinkedList.SENTINAL_TOKEN) {
      VolumeDrip.State storage dripState = self.volumeDrips[measure][currentDripToken];
      dripState.mint(
        user,
        amount,
        currentBlockNumber
      );
      currentDripToken = self.dripTokens[measure].addressMap[currentDripToken];
    }
  }

  function claimDripTokens(
    State storage self,
    address measure,
    address dripToken,
    address user,
    uint256 currentBlockNumber
  )
    internal
    returns (uint256)
  {
    VolumeDrip.State storage volumeDrip = self.volumeDrips[measure][dripToken];
    return volumeDrip.burnDrip(user, currentBlockNumber);
  }

  function hasDrip(State storage self, address measure, address dripToken) internal view returns (bool) {
    return self.dripTokens[measure].contains(dripToken);
  }

}