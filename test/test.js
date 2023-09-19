const { ethers } = require("ethers");
const TokenBuild = require("../build/contracts/Token.json");
const IUniswapV2Router02Build = require("../build/contracts/IUniswapV2Router02.json");
const IERC20Build = require("../build/contracts/IERC20.json");

const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
const wallet = new ethers.Wallet(
  "0xbffe2dc5bf6967526467e2376b204dc9945ccc071c96afe71c201b5803b755be",
  provider
);

const wallet2 = new ethers.Wallet(
  "0x8419f9f266176695adab6b0df6e9b80a7c269cd44a8920bd89761fe8603cf702",
  provider
);

async function main() {
  const UniswapV2Router02 = new ethers.Contract(
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    IUniswapV2Router02Build.abi,
    wallet
  );
  const WETH = new ethers.Contract(
    await UniswapV2Router02.WETH(),
    IERC20Build.abi,
    wallet
  );
  const TokenFactory = new ethers.ContractFactory(
    TokenBuild.abi,
    TokenBuild.bytecode,
    wallet
  );
  const token = await TokenFactory.deploy();
  await token.waitForDeployment();
  console.log(await token.name());
  console.log(await token.symbol());
  console.log(
    ethers.formatUnits(
      await token.balanceOf(wallet.address),
      await token.decimals()
    )
  );
  console.log("Token:", await token.getAddress());
  console.log("LiquidityPairAddress:", await token.liquidityPairAddress());
  console.log("approve token to router");
  console.log(
    await (
      await token.approve(
        await UniswapV2Router02.getAddress(),
        ethers.parseEther("10000000")
      )
    ).wait()
  );

  console.log("Adding Liquidity");
  console.log(
    await (
      await UniswapV2Router02.addLiquidityETH(
        await token.getAddress(),
        ethers.parseEther("10000000"),
        1,
        ethers.parseEther("5"),
        wallet.address,
        16945843470,
        { value: ethers.parseEther("100") }
      )
    ).wait()
  );
  console.log("Liquidity added");
  console.log(
    ethers.formatUnits(
      await token.balanceOf(await token.liquidityPairAddress()),
      await token.decimals()
    )
  );

  console.log(
    "wallet",
    ethers.formatUnits(
      await token.balanceOf(wallet.address),
      await token.decimals()
    )
  );
  console.log(
    "wallet2",
    ethers.formatUnits(
      await token.balanceOf(wallet2.address),
      await token.decimals()
    )
  );
  console.log(
    "tax",
    ethers.formatUnits(
      await token.balanceOf("0xbacf5fEAAB46dFe77f6c97ba0ff8aAfBc73753f6"),
      await token.decimals()
    )
  );

  console.log(
    await (
      await UniswapV2Router02.connect(wallet2).swapExactETHForTokens(
        1,
        [await UniswapV2Router02.WETH(), await token.getAddress()],
        wallet2.address,
        16945843470,
        { value: ethers.parseEther("1"), gasLimit: 30000000 }
      )
    ).wait()
  );

  console.log(
    "wallet",
    ethers.formatUnits(
      await token.balanceOf(wallet.address),
      await token.decimals()
    )
  );
  console.log(
    "wallet2",
    ethers.formatUnits(
      await token.balanceOf(wallet2.address),
      await token.decimals()
    )
  );
  console.log(
    "tax",
    ethers.formatUnits(
      await token.balanceOf("0xbacf5fEAAB46dFe77f6c97ba0ff8aAfBc73753f6"),
      await token.decimals()
    )
  );

  console.log("Selling token");
  console.log(
    "pair",
    ethers.formatUnits(
      await token.balanceOf(await token.liquidityPairAddress()),
      await token.decimals()
    )
  );
  console.log(
    "pair weth",
    ethers.formatUnits(
      await WETH.balanceOf(await token.liquidityPairAddress()),
      await token.decimals()
    )
  );
  console.log(
    "wallet",
    ethers.formatUnits(
      await token.balanceOf(wallet.address),
      await token.decimals()
    )
  );
  console.log(
    "wallet2",
    ethers.formatUnits(
      await token.balanceOf(wallet2.address),
      await token.decimals()
    )
  );
  console.log(
    "tax",
    ethers.formatUnits(
      await token.balanceOf("0xbacf5fEAAB46dFe77f6c97ba0ff8aAfBc73753f6"),
      await token.decimals()
    )
  );
  console.log(
    await (
      await token
        .connect(wallet2)
        .approve(
          await UniswapV2Router02.getAddress(),
          ethers.parseEther("10000")
        )
    ).wait()
  );

  console.log("Tokens approved");

  console.log(
    await (
      await UniswapV2Router02.connect(wallet2).swapExactTokensForETHSupportingFeeOnTransferTokens(
        await token.allowance(
          wallet2.address,
          await UniswapV2Router02.getAddress()
        ),
        0,
        [await token.getAddress(), await UniswapV2Router02.WETH()],
        wallet2.address,
        16945843470,
        { gasLimit: 30000000 }
      )
    ).wait()
  );

  console.log(
    "wallet",
    ethers.formatUnits(
      await token.balanceOf(wallet.address),
      await token.decimals()
    )
  );
  console.log(
    "wallet2",
    ethers.formatUnits(
      await token.balanceOf(wallet2.address),
      await token.decimals()
    )
  );
  console.log(
    "tax",
    ethers.formatUnits(
      await token.balanceOf("0xbacf5fEAAB46dFe77f6c97ba0ff8aAfBc73753f6"),
      await token.decimals()
    )
  );
}

main();
