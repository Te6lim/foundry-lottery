// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title A sample raffle contract
 * @author Teslim Akande
 * @notice The contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    error Raffle__SendMoreEthToEnterRaffle();

    uint256 private immutable i_enteranceFee;

    constructor(uint256 enteranceFee) {
        i_enteranceFee = enteranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_enteranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }
    }

    function pickWinner() public {}

    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
