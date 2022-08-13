pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./DydxFlashloanBase.sol";

// import './ICallee.sol';

contract dydxFlashLoanTest is DydxFlashloanBase {
    address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    address public flashUser;
    event Log(string message, uint val);

    struct MyCustomData {
        address token;
        uint repayAmount;
    }

    function initiateFLashLoan(address _token, uint256 _amount) external {
        ISoloMargin solo = ISoloMargin(SOLO);

        /*
        0 WETH
        1 SAI
        2 USDC
        3 DAI
        */
        uint marketId = _getMarketIdFromTokenAddress(SOLO, _token);

        // calculate repay amount (_amount + (2 wei))
        uint repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(SOLO, repayAmount);

        /*
        1. Withdraw
        2. Call callFunction()
        3. Deposit backwards
        */
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) external {
        require(msg.sender == SOLO, "!solo");
        require(sender == address(this), "!this contract");

        MyCustomData memory mcd = abi.decode(data, (MyCustomData));
        uint repayAmount = mcd.repayAmount;

        uint bal = IERC20(mcd.token).balanceOf(address(this));
        require(bal >= repayAmount, "bal < repay");

        // more code here...
        flashUser = sender;
        emit Log("bal", bal);
        emit Log("repay", repayAmount);
        emit Log("bal", bal - repayAmount);
    }
}
