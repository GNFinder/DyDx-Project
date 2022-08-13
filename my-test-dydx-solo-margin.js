const BN = require("bn.js");
const { ethers } = require("hardhat");
const { expect, assert } = require("chai");
// require("@nomiclabs/hardhat-waffle");
// require("@nomiclabs/hardhat-truffle5");
const { sendEther, pow } = require("./util");
const {
  DAI,
  DAI_WHALE,
  USDC,
  USDC_WHALE,
  USDT,
  USDT_WHALE,
} = require("./config");

const SOLO = "0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e";

describe("TestDyDxSoloMargin", (accounts) => {
  let WHALE = USDC_WHALE;
  let TOKEN = USDC;
  let DECIMALS = 6;
  let FUND_AMOUNT = pow(10, DECIMALS).mul(new BN(2000000));
  let BORROW_AMOUNT = pow(10, DECIMALS).mul(new BN(1000000));
  let testDyDxSoloMargin;
  let token;
  let IERC20;

  beforeEach(async function () {
    testDyDxSoloMargin = artifacts.require("dydxFlashLoanTest");
    IERC20 = artifacts.require("contracts/dydxFlashLoanTest.sol:IERC20");
    // token = await ethers.getContractFactory("IERC20");
    // token = await IERC20.deploy();
    // token = await IERC20.deployed();
    // testDyDxSoloMargin = await TestDyDxSoloMargin.deploy();
    // testDyDxSoloMargin = await TestDyDxSoloMargin.deployed();

    await sendEther(web3, accounts[0], WHALE, 1);

    // send enough token to cover fee
    const bal = await token.balanceOf(WHALE);
    assert(bal.gte(FUND_AMOUNT), "balance < fund");
    await token.transfer(testDyDxSoloMargin.address, FUND_AMOUNT, {
      from: WHALE,
    });

    const soloBal = await token.balanceOf(SOLO);
    console.log(`solo balance: ${soloBal}`);
    assert(soloBal.gte(BORROW_AMOUNT), "solo < borrow");
  });

  it("flash loan", async () => {
    const tx = await testDyDxSoloMargin.initiateFlashLoan(
      token.address,
      BORROW_AMOUNT,
      { from: WHALE }
    );

    console.log(`${await testDyDxSoloMargin.flashUser()}`);

    for (const log of tx.logs) {
      console.log(log.args.message, log.args.val.toString());
    }
  });
});
