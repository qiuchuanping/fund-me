// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
// import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

//配置合约，用于配置不同网络的配置信息
contract Config is Script{

    struct NetworkConfig{
        address priceFeed;
    }

    //MockV3Aggregator的精度，8位，1e8 = 100000000，即1美元=100000000个单位的ETH
    uint8 public constant PRICE_FEED_DECIMALS = 8;
    // 初始价格，2000e8 = 2000 * 100000000 = 200000000000000000000，即初始价格为2000美元，1e8 = 100000000
    int256 public constant PRICE_FEED_INITIAL_ANSWER = 2000e8;
    //Sepolia测试网络的chainId
    uint256 public constant SEPOLIA_CHAINID = 11155111;

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid == SEPOLIA_CHAINID){
            activeNetworkConfig = getSepoliaEthConfig();
        }else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    //Sepolia测试网络ETH/USD价格Feed地址
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(PRICE_FEED_DECIMALS,PRICE_FEED_INITIAL_ANSWER);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed:address(mockPriceFeed)
        });
        return anvilConfig;
    }
}