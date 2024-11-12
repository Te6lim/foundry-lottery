// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    uint256 private constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant LOCAL_CHAIN_ID = 31337;

    uint96 private constant MOCK_BASE_FEE = 0.25 ether;
    uint96 private constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 private constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        address account;
    }

    NetworkConfig private localNetworkConfig;

    function getSepoliaEthNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x88655614D866403E04C8A68c87bAfE58adC3048c
            });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entranceFee != 0) return localNetworkConfig;

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x0,
            callbackGasLimit: 5000000,
            subscriptionId: 0,
            linkToken: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localNetworkConfig;
    }

    function getNetworkConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory config) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            config = getSepoliaEthNetworkConfig();
        } else if (chainId == LOCAL_CHAIN_ID) {
            config = getAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getNetworkConfig() public returns (NetworkConfig memory) {
        return getNetworkConfigByChainId(block.chainid);
    }
}

contract CodeConstants {
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 constant LOCAL_CHAIN_ID = 31337;
}
