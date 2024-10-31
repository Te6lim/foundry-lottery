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
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private s_lastTimestamp;

    event EnterRaffle(address indexed player);

    constructor(uint256 enteranceFee, uint256 interval) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_enteranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit EnterRaffle({player: msg.sender});
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
        }
    }

    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
