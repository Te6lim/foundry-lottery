// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract Raffletest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address player = makeAddr("raffle player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.deploy();
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
