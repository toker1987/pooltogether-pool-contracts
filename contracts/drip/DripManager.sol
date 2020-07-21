pragma solidity ^0.6.4;

import "@nomiclabs/buidler/console.sol";

import "../prize-pool/MappedSinglyLinkedList.sol";
import "./Drip.sol";

library DripManager {
  using SafeMath for uint256;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using Drip for Drip.State;

  struct State {
    mapping(address => MappedSinglyLinkedList.Mapping) dripTokens;
    mapping(address => mapping(address => Drip.State)) drips;
  }

  function updateDrips(
    State storage self,
    address measure,
    address user,
    uint256 currentBlockNumber
  ) internal {
    uint256 measureBalance = IERC20(measure).balanceOf(user);
    uint256 measureTotalSupply = IERC20(measure).totalSupply();
    address currentDripToken = self.dripTokens[measure].addressMap[MappedSinglyLinkedList.SENTINAL_TOKEN];
    while (currentDripToken != address(0) && currentDripToken != MappedSinglyLinkedList.SENTINAL_TOKEN) {
      Drip.State storage dripState = self.drips[measure][currentDripToken];
      dripState.drip(
        user,
        measureBalance,
        measureTotalSupply,
        currentBlockNumber
      );
      currentDripToken = self.dripTokens[measure].addressMap[currentDripToken];
    }
  }

  function addDripToken(State storage self, address measure, address dripToken, uint256 dripRatePerBlock, uint256 currentBlockNumber) internal {
    require(!self.dripTokens[measure].contains(dripToken), "DripManager/drip-exists");
    if (self.dripTokens[measure].count == 0) {
      address[] memory single = new address[](1);
      single[0] = dripToken;
      self.dripTokens[measure].initialize(single);
    } else {
      self.dripTokens[measure].addAddress(dripToken);
    }

    self.drips[measure][dripToken].initialize(currentBlockNumber);
    self.drips[measure][dripToken].dripRatePerBlock = dripRatePerBlock;
  }

  function setDripRate(State storage self, address measure, address dripToken, uint256 dripRatePerBlock) internal {
    require(self.dripTokens[measure].contains(dripToken), "DripManager/drip-not-exists");
    self.drips[measure][dripToken].dripRatePerBlock = dripRatePerBlock;
  }

  function hasDripToken(State storage self, address measure, address dripToken) internal view returns (bool) {
    return self.dripTokens[measure].contains(dripToken);
  }

  function getDrip(State storage self, address measure, address dripToken) internal view returns (Drip.State storage) {
    return self.drips[measure][dripToken];
  }

  function balanceOfDrip(State storage self, address user, address measure, address dripToken) internal view returns (uint256) {
    Drip.State storage dripState = self.drips[measure][dripToken];
    return dripState.userStates[user].dripBalance;
  }

  function claimDrip(State storage self, address user, address measure, address dripToken) internal {
    Drip.State storage dripState = self.drips[measure][dripToken];
    uint256 balance = dripState.userStates[user].dripBalance;
    dripState.burnDrip(user, balance);
    IERC20(dripToken).transfer(user, balance);
  }

  function batchClaimDrip(State storage self, address user, address[] memory measures, address dripToken) internal {
    uint256 availableSupply = IERC20(dripToken).balanceOf(address(this));
    uint256 burnedBalance;
    for (uint256 i = 0; i < measures.length; i++) {
      if (burnedBalance >= availableSupply) {
        break;
      }
      Drip.State storage dripState = self.drips[measures[i]][dripToken];
      uint256 balance = dripState.userStates[user].dripBalance;
      if (burnedBalance.add(balance) > availableSupply) {
        balance = availableSupply.sub(burnedBalance);
      }
      burnedBalance = burnedBalance.add(balance);
      dripState.burnDrip(user, balance);
    }
    IERC20(dripToken).transfer(user, burnedBalance);
  }

}
