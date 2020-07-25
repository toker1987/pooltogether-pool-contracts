pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";

import "./ComptrollerStorage.sol";
import "./ComptrollerInterface.sol";

contract Comptroller is ComptrollerStorage, ComptrollerInterface {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using BalanceDripManager for BalanceDripManager.State;
  using VolumeDripManager for VolumeDripManager.State;

  function initialize() public initializer {
    __Ownable_init();
  }

  function reserveFeeMantissa() external view override returns (uint256) {
    return _reserveFeeMantissa;
  }

  function setReserveFeeMantissa(uint256 __reserveFeeMantissa) external onlyOwner returns (uint256) {
    _reserveFeeMantissa = __reserveFeeMantissa;
  }

  function addBalanceDrip(address prizeStrategy, address measure, address dripToken, uint256 dripRatePerBlock) external onlyOwner {
    balanceDrips[prizeStrategy].addDrip(measure, dripToken, dripRatePerBlock, _currentBlock());
  }

  function removeBalanceDrip(address prizeStrategy, address measure, address prevDripToken, address dripToken) external onlyOwner {
    balanceDrips[prizeStrategy].removeDrip(measure, prevDripToken, dripToken);
  }

  function setBalanceDripRate(address prizeStrategy, address measure, address dripToken, uint256 dripRatePerBlock) external onlyOwner {
    balanceDrips[prizeStrategy].setDripRate(measure, dripToken, dripRatePerBlock);
  }

  function claimBalanceDrip(address prizeStrategy, address user, address measure, address dripToken) external {
    balanceDrips[prizeStrategy].claimDripTokens(user, measure, dripToken);
  }

  function addVolumeDrip(
    address prizeStrategy,
    address measure,
    address dripToken,
    uint32 periodBlocks,
    uint128 dripRatePerBlock
  )
    external
    onlyOwner
  {
    volumeDrips[prizeStrategy].addDrip(measure, dripToken, periodBlocks, dripRatePerBlock, _currentBlock().toUint32());
  }

  function removeVolumeDrip(address prizeStrategy, address measure, address prevDripToken, address dripToken) external onlyOwner {
    volumeDrips[prizeStrategy].removeDrip(measure, prevDripToken, dripToken);
  }

  function setVolumeDripRate(address prizeStrategy, address measure, address dripToken, uint128 dripRatePerBlock) external onlyOwner {
    volumeDrips[prizeStrategy].setDripRate(measure, dripToken, dripRatePerBlock);
  }

  function claimVolumeDrip(address prizeStrategy, address user, address measure, address dripToken) external {
    volumeDrips[prizeStrategy].claimDripTokens(user, measure, dripToken, _currentBlock().toUint32());
  }

  function addReferralVolumeDrip(
    address prizeStrategy,
    address measure,
    address dripToken,
    uint32 periodBlocks,
    uint128 dripRatePerBlock
  )
    external
    onlyOwner
  {
    referralVolumeDrips[prizeStrategy].addDrip(measure, dripToken, periodBlocks, dripRatePerBlock, _currentBlock().toUint32());
  }

  function removeReferralVolumeDrip(address prizeStrategy, address measure, address prevDripToken, address dripToken) external onlyOwner {
    referralVolumeDrips[prizeStrategy].removeDrip(measure, prevDripToken, dripToken);
  }

  function setReferralVolumeDripRate(address prizeStrategy, address measure, address dripToken, uint128 dripRatePerBlock) external onlyOwner {
    referralVolumeDrips[prizeStrategy].setDripRate(measure, dripToken, dripRatePerBlock);
  }

  function claimReferralVolumeDrip(address prizeStrategy, address user, address measure, address dripToken) external {
    referralVolumeDrips[prizeStrategy].claimDripTokens(user, measure, dripToken, _currentBlock().toUint32());
  }

  function afterDepositTo(
    address to,
    uint256 amount,
    uint256 balance,
    uint256 totalSupply,
    address controlledToken,
    address referrer
  )
    external
    override
  {
    balanceDrips[msg.sender].updateDrips(
      controlledToken,
      to,
      balance.sub(amount), // we want the original balance
      totalSupply.sub(amount),
      _currentBlock()
    );

    volumeDrips[msg.sender].deposit(
      controlledToken,
      to,
      amount,
      _currentBlock()
    );

    if (referrer != address(0)) {
      referralVolumeDrips[msg.sender].deposit(
        controlledToken,
        to,
        amount,
        _currentBlock()
      );
    }
  }

  function afterWithdrawFrom(
    address to,
    uint256 amount,
    uint256 balance,
    uint256 totalSupply,
    address controlledToken
  )
    external
    override
  {
    balanceDrips[msg.sender].updateDrips(
      controlledToken,
      to,
      balance.add(amount), // we want the original balance
      totalSupply.add(amount),
      _currentBlock()
    );
  }

  /// @notice returns the current time.  Used for testing.
  /// @return The current time (block.timestamp)
  function _currentBlock() internal virtual view returns (uint256) {
    return block.number;
  }

}