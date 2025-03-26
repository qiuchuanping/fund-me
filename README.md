# FundMe
本智能合约实现了向合约`捐赠`以太币，并在需要时从合约中`提取`捐赠，同时可以`查询`捐赠（捐赠总资金-已提取资金），其中`提取`必须是合约的拥有者才能使用。

本项目是在学习`Patrick Collins`的《Foundry Fundamentals》系列课程时编写的项目。

课程原地址：https://updraft.cyfrin.io/courses/foundry
B站精翻地址： https://www.bilibili.com/video/BV13a4y1F7V3

本次项目没有再使用Remix了，而是使用了IDE工具Visual Studio Code ，集成更专业的Foundry框架开发,更接近真实的开发环境，完成了开发、测试、部署等一系列操作。

前端项目：https://github.com/qiuchuanping/fund-me-web.git

## Install Foundry 
```shell
$ curl -L https://foundry.paradigm.xyz | bash
$ foundryup
```
> 安装完成后，会在~/.bashrc文件中添加foundry的环境变量，需要执行以下命令才能生效
```shell
$ source ~/.bashrc
```
> foundryup命令执行时可能失败，foundry_stable_linux_amd64.tar.gz文件下载失败，可以手动下载。下载完成后，将foundry_stable_linux_amd64.tar.gz文件解压到~/.foundry/bin目录下
```shell
$ tar -zxvf foundry_stable_linux_amd64.tar.gz -C ~/.foundry/bin
```
> 执行以下命令，使环境变量生效
```shell
$ source ~/.bashrc
```
> 执行以下命令验证
```shell
$ forge --version
$ anvil --version
$ chisel --version
$ cast --version
```
## 初始化项目
```shell
$ forge init fundme
```
> 可能会要求输入github的用户名和密码，输入后会在当前目录下生成fundme项目
```shell
$ git config --global user.email "xxx@126.com"
$ git config --global user.name "xxx"
```
## Install 依赖
> 项目中会使用到chainlink预言机来获取加密货币价格，需要安装chainlink-brownie-contracts依赖
- 安装chainlink-brownie-contracts依赖
```shell
$ forge install smartcontractkit/chainlink-brownie-contracts --no-commit
```
- 更新foundry.toml的remappings配置
```shell
remappings = [
  '@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/',
]
```
## 单元测试
- 运行所有测试
```shell
$ forge test
```
- 查看测试覆盖率
```shell
$ forge coverage
```

- 运行指定测试方法
```shell
$ forge test --match-test testMinimumFunding
$ forge test --mt testMinimumFunding
```
- 在本地环境模拟测试网、主网等
```shell
$ forge test --fork-url <your_rpc_url>
```
- fork-url 参数说明
1. --fork-url 允许你指定一个以太坊节点（如 Infura、Alchemy 或本地节点）的 RPC URL
   
   > 例如：在alchemy平台申请的rpc url为https://eth-sepolia.g.alchemy.com/v2/BxZDQXWdaktq45p3jtPjEduwwV8DDbqB
2. forge测试框架会从该节点获取链上数据，并在本地创建一个分叉环境,所有测试都在这个分叉环境中运行，而不是在真实的链上
3. 通过 --fork-url，开发者可以在本地安全地测试与主网或其他链的交互，而无需担心影响真实链上状态或消耗真实 gas。

```shell
$ forge test --fork-url https://eth-sepolia.g.alchemy.com/v2/BxZDQXWdaktq45p3jtPjEduwwV8DDbqB
```

## Mock合约的使用
- 查找priceFeed的Mock合约
  安装chainlink-brownie-contracts依赖后，会在lib目录下生成chainlink-brownie-contracts的合约代码，其中包含MockV3Aggregator.sol合约，用于模拟价格Feed的合约，路径为：
  /lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol
- 拷贝MockV3Aggregator.sol合约到test/mocks目录下
  由于sepolia测试网上priceFeed合约版本号为version=4，合约源码中version=0,为了与测试环境保持一致，需要将MockV3Aggregator.sol合约中的version=0修改为version=4，否在测试代码不能兼容本地环境和sepolia测试网络
  由于路径变更了，需要修改源码中的import语句
  变更前：
  ```solidity
  import "../shared/interfaces/AggregatorV2V3Interface.sol";
  ```
  变更后：
  ```solidity
  import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
  ```
  > 也可以不用拷贝，直接使用lib目录下的MockV3Aggregator.sol合约，但是需要修改版本号，破坏了原来的代码结构，不推荐使用
- 修改Config.s.sol合约脚本
  修改获取本地配置方法，将Mock合约部署到本地环境，并返回合约地址
  1. 新增依赖
  ```solidity
  import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
  ```
  2. 修改getAnvilEthConfig方法
  ```solidity
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
  ```

## Gas Snapshots
- 查看Gas使用情况
```shell
$ forge snapshot
```
> 同时会生成.gas-snapshots文件

- 代码实现
```solidity
  uint256 gasStart = gasleft(); //查看gas剩余量
  console.log("Gas Start: %s", gasStart);
  vm.txGasPrice(1); //默认0，设置gas价格为1

  vm.prank(fundMe.getOwner());
  fundMe.withdraw(); // 执行交易

  uint256 gasEnd = gasleft(); //再次查看gas剩余量
  console.log("Gas End: %s", gasEnd);
  
  uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //交易使用的gas量
  console.log("Gas Used: %s", gasUsed);
```

## Test Address
- 在本地测试过程中，需要使用测试地址进行测试，forge-std提供了以下方式生成测试地址
```solidity
address test = makeAddr("test"); //生成测试地址
// address hacker = address(uint160(1)); 也可通过uint160类型转换生成测试地址
vm.deal(test, 10e18); //给生成的地址发送10 ETH，用于测试
vm.prank(test); //设置以下交易的调用者

// 也可以将prank和deal合并为一个函数
hoax(test,10e18); //设置调用者为test，给test发送10 ETH
```

## Storage Layout
- 查看合约的storage布局
```shell
$ forge inspect FundMe storage-layout
```
> 1.部署合约
> ```shell
> $ forge script script/DeployFundMe.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

[⠊] Compiling...
No files changed, compilation skipped
Script ran successfully.

== Return ==
0: contract FundMe 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
> ```
> 2.执行以下命令查看合约的storage布局
```shell
$ cast storage <合约地址> <槽索引>
$ cast storage 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 0 
```

## Anvil
- 运行本地测试网节点
```shell
$ anvil
```

## Deploy
- 部署到本地Anvil测试网
> 增加环境变量
```shell
$ vim .env
LOCAL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
LOCAL_RPC_URL=http://127.0.0.1:8545
$ source .env
$ echo $LOCAL_PRIVATE_KEY
$ echo $LOCAL_RPC_URL
```
> 执行以下命令
```shell
$ forge script script/DeployFundMe.s.sol --rpc-url $LOCAL_RPC_URL --private-key $LOCAL_PRIVATE_KEY --broadcast
```

-部署到sepolia测试网
> 增加环境变量
```shell
$ vim .env
SEPOLIA_PRIVATE_KEY=xxxx
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xxxx
$ source .env
$ echo $SEPOLIA_PRIVATE_KEY
$ echo $SEPOLIA_RPC_URL
```
> 执行以下命令
```shell
$ forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PRIVATE_KEY --broadcast
```
