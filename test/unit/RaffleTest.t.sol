// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract Raffletest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;

    event EnterRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    address player = makeAddr("raffle player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    modifier raffleEntered() {
        vm.startPrank(player);
        raffle.enterRaffle{value: networkConfig.entranceFee}();
        vm.stopPrank();

        vm.warp(block.timestamp + networkConfig.interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.deploy();
        networkConfig = helperConfig.getNetworkConfig();
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
        raffle.enterRaffle{value: networkConfig.entranceFee}();
        vm.stopPrank();
        address playerRecorded = raffle.getPlayer(0);
        assert(player == playerRecorded);
    }

    function testEnteringRaffleEmitEvent() public {
        vm.startPrank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(player);
        raffle.enterRaffle{value: networkConfig.entranceFee}();
        vm.stopPrank();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");

        vm.prank(player);
        vm.expectRevert(Raffle.Raffel__RaffleNotOpen.selector);
        raffle.enterRaffle{value: networkConfig.entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfIthasNoBalance() public {
        vm.warp(block.timestamp + networkConfig.interval + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen()
        public
        raffleEntered
    {
        raffle.performUpkeep("");

        (bool upkeedNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeedNeeded);
    }

    // perform upkeep tests

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__RaffleUpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitRequestId()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    //fuzz testing
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).fulfillRandomWords(
                randomRequestId,
                address(raffle)
            );
    }

    function testFulfilRandomWordsPicksAWinnerResetAndSendMoney()
        public
        raffleEntered
    {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: networkConfig.entranceFee}();
        }
        uint256 startingTimestamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        /*uint256[] memory words = new uint256[](1);
        words[0] = 1;
        raffle.sendToFulfilRandomWords(uint256(requestId), words);*/
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).fulfillRandomWords(
                uint256(requestId),
                address(raffle)
            );

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = networkConfig.entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimestamp);
    }
}
