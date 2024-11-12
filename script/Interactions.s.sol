// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig.NetworkConfig memory networkConfig = new HelperConfig()
            .getNetworkConfig();
        address vrfCoordinator = networkConfig.vrfCoordinator;
        (uint256 subId, ) = createSubscription(
            vrfCoordinator,
            networkConfig.account
        );
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console2.log("creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console2.log("your subsctiption Id is: ", subId);
        console2.log(
            "please update the subscription in your HelperConfig.s.sol"
        );
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig.NetworkConfig memory networkConfig = new HelperConfig()
            .getNetworkConfig();
        fundSubscription(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.linkToken,
            networkConfig.account
        );
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console2.log("funding subscription: ", subscriptionId);
        console2.log("using vrfCoordinator: ", vrfCoordinator);
        console2.log("on chain: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig.NetworkConfig memory networkConfig = new HelperConfig()
            .getNetworkConfig();
        addConsumer(
            mostRecentlyDeployed,
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.account
        );
    }

    function addConsumer(
        address contractToAddVrf,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        console2.log("adding consumer conrtract: ", contractToAddVrf);
        console2.log("to vrfCoordinator: ", vrfCoordinator);
        console2.log("on chain id: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddVrf
        );
        vm.stopBroadcast();
    }
}
