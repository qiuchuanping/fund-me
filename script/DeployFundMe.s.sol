// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {Config} from "./Config.s.sol";

contract DeployFundMe is Script {

    function run() external returns (FundMe){
        // 调用vm之前的代码，都在本地执行，不会在链上执行 ，不消耗gas
        Config config = new Config();
        //activeNetworkConfig 返回的是一个结构体，接收返回参数时可通过（address a,uint256 b）的形式，若结构体只有1个属性时，可直接按相应类型接收
        //(address priceFeed) = config.activeNetworkConfig(); 括号可以省略
        address priceFeed = config.activeNetworkConfig();

        // 调用vm之后的代码，都在链上执行，会消耗gas
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
    
}