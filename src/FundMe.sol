
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { PriceConverter } from "./PriceConverter.sol";

//自定义错误
error NotOwner();

//捐助合约，最低需捐助2美元
//spolia testnet contract address 0x9730D638Bb0ffd3FEc290dAfd3b7Bb70a848A467
contract FundMe{

    //将价格转换器附加到uint256类型上，便于通过“.”+函数名的方式调用库函数
    using PriceConverter for uint256;

    //最小捐赠金额，2美元，统一单位为1e18
    uint256 public constant MIN_FUND_AMOUNT = 2e18;

    //捐赠者集合
    address[] private funders;
    //捐赠者捐赠金额映射
    mapping (address => uint256) private funderToAmount;

    AggregatorV3Interface private priceFeed; 

    //合约的拥有者
    address private immutable owner;
    //构造函数设置合约拥有者
    constructor(address _priceFeed){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed); 
    }

    //修饰器，校验合约拥有者
    modifier onlyOwner(){
        // require(owner == msg.sender,"Only the owner can call this!");

        // 自定义错误，会消耗gas，但是比require更节省gas
        if(owner != msg.sender){
            revert NotOwner();
        }
        _;
    }

    //捐助
    function fund() public payable {
        //校验最小金额限制
        require(msg.value.getUSDFromETH(priceFeed) >= MIN_FUND_AMOUNT,"Amount must be greater than minimum");
        funders.push(msg.sender);
        funderToAmount[msg.sender] += msg.value;
    } 

    // 提现
    function withdraw(uint256 amount) public onlyOwner{
        uint256 funderCount = funders.length;
        //取出所有资金
        for (uint256 funderIndex = 0;funderIndex < funderCount;funderIndex++){
            address funder = funders[funderIndex];
            funderToAmount[funder] = 0;
        }
        //清空funder
        funders = new address[](0);

        uint256 balance = address(this).balance;
        require(balance >= amount,"Not enough balance!");
        //从当前合约地址余额转出到合约调用者
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success,"withdraw failed!");
    }

    //未通过fund函数对合约进行捐赠时（例如从matemask中send），会触发以下两个特殊函数
    //msg.data为空，调用receive函数，如果为定义receive函数，则调用fallback函数，
    //msg.data不为空，调用指定函数，指定函数未定义，则调用fallback
    //receive函数：处理纯以太币转账（msg.data为空）。
    receive() external payable { 
        fund();
    }

    //fallback函数：处理未匹配的函数调用（包括纯以太币转账和带有数据的调用）。
    fallback() external payable {
        fund();
    }

    //查询合约余额
    function balanceOf() public view returns(uint256){
        return address(this).balance; //wei
    }

    function getPriceFeedVersion() public view returns(uint256){
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); 
        return priceFeed.version();
    }

    function getFunder(uint256 _index) external view returns(address){
        return funders[_index];
    }

    function getFunderAmount(address _funder) external view returns(uint256){
        return funderToAmount[_funder];
    }

    function getOwner() external view returns(address){
        return owner;
    }

}