// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

//ETH->UDS价格转换库
library PriceConverter{

    //通过chainlink喻言机获取ETH兑美元
    function getETHToUSDPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        // spolia testnet ETH->USD address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //链接喻言机，查询ETH兑美元
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); 
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        //answer单位为1e8,转换为1e18 & int类型转换uint256
        return uint256(answer * 1e10);
    }

    //ETH 转 USD
    function getUSDFromETH(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns (uint256){
        //查询ETH兑美元价格
        uint256 ethPrice = getETHToUSDPrice(priceFeed);
        //转换为美元
        return (ethAmount * ethPrice) / 1e18;
    }
}