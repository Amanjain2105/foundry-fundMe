// SPDX-License-Identifier: MIT

// 1. Deploy mocks when we are on local chain
// 2. Keep track of contract address across different chains

pragma solidity ^0.8.19;

import {Script} from "@forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //If we are on local chain we deploy mocks
    //Otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig; 

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e18;

    struct NetworkConfig{
        address priceFeed;
    }

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else{
            activeNetworkConfig = getorCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });

    }

    function getorCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        //priceFeed address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
            );
        vm.stopBroadcast();
        NetworkConfig memory anvilConFig = NetworkConfig ({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConFig;
    }
}