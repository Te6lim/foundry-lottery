// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    uint256 private constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 private constant LOCAL_CHAIN_ID = 31337;

    uint96 private constant MOCK_BASE_FEE = 0.25 ether;
    uint96 private constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 private constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    struct NetworkConfig {
        uint256 enteranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        uint256 chainId;
    }

    NetworkConfig private localNetworkConfig;

    function getSepoliaEthNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                enteranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                chainId: ETH_SEPOLIA_CHAIN_ID
            });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.chainId != 0) return localNetworkConfig;

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            enteranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x0,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            chainId: LOCAL_CHAIN_ID
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
}
