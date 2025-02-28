---
title: "我从 Uniswap 代码中学到的合约开发小技巧"
date: 2024-10-31 19:20:00
categories: 技术
tags:
  - Web3
---

**没想到合约还能这么写？** 这是我最近发出的最多的感慨了~

最近在写一个去中心化交易所开发的教程 [https://github.com/WTFAcademy/WTF-Dapp](https://github.com/WTFAcademy/WTF-Dapp)，参考了 Uniswap V3 的代码实现，学习到了很多知识点。笔者之前开发过简单的 NFT 合约，这次是第一次尝试开发 Defi 的合约，相信这些小技巧会对想要学习合约开发的小白会很有帮助。

合约开发的大佬可以直接前往 https://github.com/WTFAcademy/WTF-Dapp 一起来贡献代码，为 Web3 添砖加瓦~

接下来就让我们看看这些小技巧吧，有的甚至称得上是奇技淫巧。

## 01 合约部署的合约地址有办法做到是可预测的

我们一般部署合约得到的都是一个看上去随机的地址，因为和 `nonce` 有关，所以合约地址不好预测。但是在 Uniswap 中，我们会有这样的需求：需要通过交易对和相关信息就能推理出合约的地址。这在很多情况下很管用，比如判断交易的权限，或者获取池子的地址等。

在 Uniswap 中，创建合约是通过 `pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());` 这样的代码来创建的。通过添加了 `salt` 来使用 CREATE2 (

https://github.com/AmazingAng/WTF-Solidity/blob/main/25_Create2/readme.md) 的方式来创建合约，这样的好处是创建出来的合约地址是可预测的，地址生成的逻辑是 `新地址 = hash("0xFF",创建者地址, salt, initcode)` 。

这部分内容你可以查看 WTF-DApp 课程的  
https://github.com/WTFAcademy/WTF-Dapp/blob/main/P103_Factory/readme.md 这一章来了解更多。

## 02 善用回调函数

在 Solidity 中，合约之间可以互相调用。有一种场景是 A 在某个方法调用 B，B 在被调用的方法中回调 A，这在某些场景中也很管用。

在 Uniswap 中，当你调用 `UniswapV3Pool` 合约的 `swap` 方法交易时，它会回调 `swapCallback`，回调会传入计算出来的本次交易实际需要的 `Token`，调用方需要在回调中将交易需要的 Token 转入 `UniswapV3Pool`，而不是把 `swap` 方法拆开为两部分让调用方调用，这样确保了 `swap` 方法的安全性，确保整个逻辑都是被完整执行的，而不需要繁琐的变量记录来确保安全性。

代码片段如下：

```solidity
if (amount0 > 0) balance0Before = balance0();
if (amount1 > 0) balance1Before = balance1();
IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');
```

你可以学习课程中关于交易的部分内容了解更多  
https://github.com/WTFAcademy/WTF-Dapp/blob/main/P106_PoolSwap/readme.md。

## 03 用异常来传递信息，用 try catch 来实现交易的预估

在参考 Uniswap 的代码时，我们发现在它的  
https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/Quoter.sol  
 这个合约中，把 `UniswapV3Pool` 的 `swap` 方法用 `try catch` 包住执行了一下：

```solidity
/// @inheritdoc IQuoter
function quoteExactInputSingle(
  address tokenIn,
  address tokenOut,
  uint24 fee,
  uint256 amountIn,
  uint160 sqrtPriceLimitX96
) public override returns (uint256 amountOut) {
  bool zeroForOne = tokenIn < tokenOut;

  try
  getPool(tokenIn, tokenOut, fee).swap(
    address(this), // address(0) might cause issues with some tokens
    zeroForOne,
    amountIn.toInt256(),
    sqrtPriceLimitX96 == 0
    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
    : sqrtPriceLimitX96,
    abi.encodePacked(tokenIn, fee, tokenOut)
  )
  {} catch (bytes memory reason) {
    return parseRevertReason(reason);
  }
}
```

这个是为啥呢？因为我们需要模拟 `swap` 方法来预估交易需要的 Token，但是因为预估的时候并不会实际产生 Token 的交换，所以会报错。在 Uniswap 中，它通过在交易的回调函数中抛出一个特殊的错误，然后捕获这个错误，从错误信息中解析出需要的信息。

看上去挺 Hack 的，但是也很实用。这样就不需要针对预估交易的需求去改造 swap 方法了，逻辑也更简单。在我们的课程中，我们也参考这个逻辑实现了  
https://github.com/WTFAcademy/WTF-Dapp/blob/main/demo-contract/contracts/wtfswap/SwapRouter.sol 这个合约。

## 04 用大数来解决精度问题

在 Uniswap 的代码中，有很多的计算逻辑，比如按照当前价格和流动性计算交换的 Token，那这个过程中我们要避免除法操作的时候丢失精度。在 Uniswap 中，计算过程会经常用到 `<< FixedPoint96.RESOLUTION` 这个操作，它代表左移 96 位，相当于乘以 `2^96`。左移之后再做除法运算，这样可以在正常交易不溢出（一般用 `uint256` 来计算，还足够）的情况下保证精度。

代码如下（通过价格和流动性计算交易所需要的 Token 数）：

```solidity
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(
                        numerator1,
                        numerator2,
                        sqrtRatioBX96
                    ),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) /
                    sqrtRatioAX96;
    }

```

可以看到，首先在 Uniswap 中价格都是用平方根乘以 `2^96` （对应上面代码中的 `sqrtRatioAX96` 和 `sqrtRatioBX96`），然后流动性 `liquidity` 会左移计算出 `numerator1`。在下面的计算中，`2^96` 会在计算过程中被约掉，得到最后的结果。

当然，不管如何，理论上还是会有精度的丢失的，不过这种情况都是最小单位的丢失了，是可以接受的。

更多内容你可以学习  
https://github.com/WTFAcademy/WTF-Dapp/blob/main/P106_PoolSwap/readme.md 这一篇课程了解更多。

## 05 用 Share 的方式来计算收益

在 Uniswap 中，我们需要记录 LP（流动性提供者）的手续费收益。显然，我们不能在每次交易的时候都给每个 LP 记录各自的手续费，这样会消耗大量的 Gas。那怎么处理呢？

在 Uniswap 中，我们可以看到 `Position` 中定义了如下结构体：

```solidity
library Position {
    // info stored for each user's position
    struct Info {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }
```

其中包含了 `feeGrowthInside0LastX128` 和 `feeGrowthInside1LastX128`，他们记录了每个头寸（Position）上一次提取手续费时候每个流动性应该收到的手续费。

简单点说，我只要记录总的手续费和每个流动性应该分配到多少手续费即可，这样 LP 提取手续费的时候按照手中的流动性就可以计算出他有多少可以提取的手续费。就好像你持有某个公司的股票，你要提取股票收益的时候只要知道公司历史的每股得收益，以及你上次提取时的收益即可。

之前我们在[《巧妙的合约设计，看看 stETH 如何按天自动发放收益？让你的 ETH 参与质押获取稳定利息》](http://mp.weixin.qq.com/s?__biz=MzkyNjUxNjU2Mg==&mid=2247485629&idx=1&sn=43737fa1e53beec92b3131f2f5c36320&chksm=c2375c80f540d5966dabfa4cd7fac4e00ccf992111823e800d2eb311cdef68c641502067a1c5&scene=21#wechat_redirect)  
这篇文章中也介绍过 stETH 的收益计算方法，也是类似的道理。

## 06 不是所有信息都需要从链上获取

链上的存储是相对昂贵的，所以我们并不是所有的信息都要上链，或者从链上获取。比如 Uniswap 前端网站调用的很多接口就是传统的 Web2 的接口。

交易池的列表、交易池的信息等都可以存储在普通的数据库中，有的可能需要定期从链上同步，但是我们并不需要去实时调用链或者节点服务提供的 PRC 接口来获取相关数据。

当然现在很多区块链 PRC 的供应商都提供了一些高级的接口，你可以以更快速更便宜的方式获取到一些数据，这也是类似的道理。比如 ZAN 就提供了类似获取某个用户下所有 NFT 的接口，这些信息显然是可以通过缓存来提高性能和效率的，你可以访问  
https://zan.top/service/advance-api 这个获取更多。

当然，关键的交易肯定是在链上进行的。

## 07 学会合约的拆分，还要学会利用类似 ERC721 这样已有的标准合约

一个项目可能包含多个实际部署的合约，即便是实际部署只有一个合约，但是我们代码可以通过继承的方式把合约拆分为多个合约来维护。

比如在 Uniswap 中，  
https://github.com/Uniswap/v3-periphery/blob/main/contracts/NonfungiblePositionManager.sol 合约就继承了很多合约，代码如下：

```solidity
contract NonfungiblePositionManager is
    INonfungiblePositionManager,
    Multicall,
    ERC721Permit,
    PeripheryImmutableState,
    PoolInitializer,
    LiquidityManagement,
    PeripheryValidation,
    SelfPermit
{
```

而且你在看 `ERC721Permit` 合约的实现时，你会发现它直接使用了 `@openzeppelin/contracts/token/ERC721/ERC721.sol` 合约，这样一方面方便通过 NFT 的方式来管理头寸，另外一方面也可以用已有的标准的合约来提高合约的开发效率。

在我们的课程中，你可以学习  
`https://github.com/WTFAcademy/WTF-Dapp/blob/main/P108_PositionManager/readme.md` 尝试开发一个简单的 ERC721 的合约来管理头寸。

## 08 总结

看再多的文章也不如自己上手开发来得实在，在尝试自己实现一个简易版的去中心化交易所的过程中能让你更深刻的理解 Uniswap 的代码实现，也可以学习到更多实际项目中会体会到的知识点。

WTF-DApp 课程是 ZAN 的开发者社区和 WTF Academy 开发者社区同学共同完成的开源课程。如果你也对 Web3，对 Defi 项目开发感兴趣，你可以参考我们的实战课程  
https://github.com/WTFAcademy/WTF-Dapp，一步一步完成一个简易版的交易所，相信一定会对你有所帮助~

![](10681691b822be0dfb48548bb0b37089.gif)

> 这篇文章最早发布在 ZAN 的公众号[《Web3 新手系列：我从 Uniswap 代码中学到的合约开发小技巧》](https://mp.weixin.qq.com/s/4B54JR6gm4nZCcwcDotp4w)
