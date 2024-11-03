// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract Raffletest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    event EnterRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    address player = makeAddr("raffle player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.deploy();
        vm.deal(player, STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertOnInsufficientFunds() public {
        vm.prank(player);
        vm.expectRevert(Raffle.Raffle__SendMoreEthToEnterRaffle.selector);

        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenEntered() public {
        vm.startPrank(player);
        raffle.enterRaffle{
            value: helperConfig.getNetworkConfig().entranceFee
        }();
        vm.stopPrank();
        address playerRecorded = raffle.getPlayer(0);
        assert(player == playerRecorded);
    }

    function testEnteringRaffleEmitEvent() public {
        vm.startPrank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(player);
        raffle.enterRaffle{
            value: helperConfig.getNetworkConfig().entranceFee
        }();
        vm.stopPrank();
    }
}
