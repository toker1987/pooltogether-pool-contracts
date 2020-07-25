pragma solidity ^0.6.4;

library ExtendedSafeCast {

  /**
    * @dev Converts an unsigned uint256 into a unsigned uint112.
    *
    * Requirements:
    *
    * - input must be less than or equal to maxUint112.
    */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value < 2**112, "SafeCast: value doesn't fit in an uint112");
    return uint112(value);
  }

  /**
    * @dev Converts an unsigned uint256 into an unsigned uint192.
    *
    * Requirements:
    *
    * - input must be less than or equal to maxUint192.
    */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value < 2**192, "SafeCast: value doesn't fit in an uint192");
    return uint192(value);
  }

}