// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";


contract FundMeTest is Test{
    FundMe fundMe;

    //使用forge的makeAddr函数生成一个地址，用于测试
    address private USER = makeAddr("hell");
    
    //初始化，首先执行setUp函数，然后执行其他test函数
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        //给生成的地址发送10 ETH，用于测试
        vm.deal(USER, 10e18);
    }

    function testMinimumFunding() public view {
        assertEq(fundMe.MIN_FUND_AMOUNT(), 2e18);
    }

    function testOwner() public view {
        //当通过在setUp中new FundMe()部署时，msg.sender 调用 FundMeTest 合约，再由 FundMeTest 部署 FundMe ,因此owner是FundMeTest合约的地址，而不是msg.sender
        // assertEq(fundMe.owner(),address(this));

        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testPriceFeedVersion() public view {
        assertEq(fundMe.getPriceFeedVersion(),4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert();//期望以下代码抛出异常，若没有抛出异常，则测试失败
        fundMe.fund(); //发送0 ETH，抛出异常，至少2ETH
    }

    function testFundUpdatesFundData() public {
        vm.prank(USER); //将USER设置为调用者
        fundMe.fund{value: 2e18}(); //发送2 ETH
        assertEq(fundMe.getFunder(0),USER);
        assertEq(fundMe.getFunderAmount(USER),2e18);
    }

    modifier funded() {
        vm.prank(USER); //将USER设置为调用者
        console.log("Funder: %s", USER);
        console.log("Funder Balance: %s", USER.balance);
        console.log("FundMe Balance: %s", address(fundMe).balance);
        console.log("FundMe Owner : %s",  fundMe.getOwner());
        uint256 amount = 0.001 * 10 ** 18;
        fundMe.fund{value: amount}(); //发送2 ETH
        _;
    }

    function testWithdrawWithASingleFunder() public funded{
        //arrange
       uint256 startingOwnerBalance = fundMe.getOwner().balance;
       console.log("Starting Owner Balance: %s", startingOwnerBalance);
       uint256 startingFundMeBalance = address(fundMe).balance;
       console.log("Starting FundMe Balance: %s", startingFundMeBalance);
       //提现
    //    uint256 gasStart = gasleft();
    //    console.log("Gas Start: %s", gasStart);
    //    vm.txGasPrice(1); //默认0，设置gas价格为1
       vm.prank(fundMe.getOwner());
       fundMe.withdraw(startingFundMeBalance); //调用withdraw函数，将所有资金取出
    //    uint256 gasEnd = gasleft();
    //    console.log("Gas End: %s", gasEnd);
    //    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    //    console.log("Gas Used: %s", gasUsed);
       //校验
       uint256 endingOwnerBalance = fundMe.getOwner().balance;
       console.log("Ending Owner Balance: %s", endingOwnerBalance);
       uint256 endingFundMeBalance = address(fundMe).balance;
       console.log("Ending FundMe Balance: %s", endingFundMeBalance);
       assertEq(endingFundMeBalance,0);
       assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public {
        //10个用户发起捐赠
        console.log("FundMe Owner : %s",  fundMe.getOwner());
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i <= numberOfFunders; i++){
            //prank new address
            //deal new address
            //fund
            //v0.8以后，address(uint160(i))可以直接转换为address类型，uint160类型和address位数一样，所以可以直接转换
            address hacker = address(i);
            // vm.prank(hacker); //设置调用者为hacker
            // vm.deal(hacker, 10e18); //给hacker发送10 ETH
            // 也可以将prank和deal合并为一个函数
            hoax(hacker,10e18); //设置调用者为hacker，给hacker发送10 ETH
            fundMe.fund{value: 2e18}();
            console.log("funder address: %s fund success.",hacker);
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        console.log("Starting Owner Balance: %s", startingOwnerBalance);
        uint256 startingFundMeBalance = address(fundMe).balance;
        console.log("Starting FundMe Balance: %s", startingFundMeBalance);
        //提现
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(startingFundMeBalance); //调用withdraw函数，将所有资金取出
        //校验
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        console.log("Ending Owner Balance: %s", endingOwnerBalance);
        uint256 endingFundMeBalance = address(fundMe).balance;
        console.log("Ending FundMe Balance: %s", endingFundMeBalance);
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance);
        //校验每个捐赠者的余额
        for(uint160 i = startingFunderIndex; i <= numberOfFunders; i++){
            address hacker = address(i);
            assertEq(fundMe.getFunderAmount(hacker),0);
        }
    }

    function testBalance() public funded {
        vm.prank(fundMe.getOwner());
        uint256 balance = fundMe.balanceOf();
        console.log(balance);
    }

}

