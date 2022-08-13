// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

// -- library -- //
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// -- interface -- //
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}
library Account {
  enum Status {
    Normal,
    Liquid,
    Vapor
  }
  struct Info {
    address owner; // The address that owns the account
    uint number; // A nonce that allows a single address to control many accounts
  }
  struct accStorage {
    mapping(uint => Types.Par) balances; // Mapping from marketId to principal
    Status status;
  }
}

library Actions {
  enum ActionType {
    Deposit, // supply tokens
    Withdraw, // borrow tokens
    Transfer, // transfer balance between accounts
    Buy, // buy an amount of some token (publicly)
    Sell, // sell an amount of some token (publicly)
    Trade, // trade tokens against another account
    Liquidate, // liquidate an undercollateralized or expiring account
    Vaporize, // use excess tokens to zero-out a completely negative account
    Call // send arbitrary data to an address
  }

  enum AccountLayout {
    OnePrimary,
    TwoPrimary,
    PrimaryAndSecondary
  }

  enum MarketLayout {
    ZeroMarkets,
    OneMarket,
    TwoMarkets
  }

  struct ActionArgs {
    ActionType actionType;
    uint accountId;
    Types.AssetAmount amount;
    uint primaryMarketId;
    uint secondaryMarketId;
    address otherAddress;
    uint otherAccountId;
    bytes data;
  }

  struct DepositArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint market;
    address from;
  }

  struct WithdrawArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint market;
    address to;
  }

  struct TransferArgs {
    Types.AssetAmount amount;
    Account.Info accountOne;
    Account.Info accountTwo;
    uint market;
  }

  struct BuyArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint makerMarket;
    uint takerMarket;
    address exchangeWrapper;
    bytes orderData;
  }

  struct SellArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint takerMarket;
    uint makerMarket;
    address exchangeWrapper;
    bytes orderData;
  }

  struct TradeArgs {
    Types.AssetAmount amount;
    Account.Info takerAccount;
    Account.Info makerAccount;
    uint inputMarket;
    uint outputMarket;
    address autoTrader;
    bytes tradeData;
  }

  struct LiquidateArgs {
    Types.AssetAmount amount;
    Account.Info solidAccount;
    Account.Info liquidAccount;
    uint owedMarket;
    uint heldMarket;
  }

  struct VaporizeArgs {
    Types.AssetAmount amount;
    Account.Info solidAccount;
    Account.Info vaporAccount;
    uint owedMarket;
    uint heldMarket;
  }

  struct CallArgs {
    Account.Info account;
    address callee;
    bytes data;
  }
}

library Decimal {
  struct D256 {
    uint value;
  }
}

library Interest {
  struct Rate {
    uint value;
  }

  struct Index {
    uint96 borrow;
    uint96 supply;
    uint32 lastUpdate;
  }
}

library Monetary {
  struct Price {
    uint value;
  }
  struct Value {
    uint value;
  }
}

library Storage {
  // All information necessary for tracking a market
  struct Market {
    // Contract address of the associated ERC20 token
    address token;
    // Total aggregated supply and borrow amount of the entire market
    Types.TotalPar totalPar;
    // Interest index of the market
    Interest.Index index;
    // Contract address of the price oracle for this market
    address priceOracle;
    // Contract address of the interest setter for this market
    address interestSetter;
    // Multiplier on the marginRatio for this market
    Decimal.D256 marginPremium;
    // Multiplier on the liquidationSpread for this market
    Decimal.D256 spreadPremium;
    // Whether additional borrows are allowed for this market
    bool isClosing;
  }

  // The global risk parameters that govern the health and security of the system
  struct RiskParams {
    // Required ratio of over-collateralization
    Decimal.D256 marginRatio;
    // Percentage penalty incurred by liquidated accounts
    Decimal.D256 liquidationSpread;
    // Percentage of the borrower's interest fee that gets passed to the suppliers
    Decimal.D256 earningsRate;
    // The minimum absolute borrow value of an account
    // There must be sufficient incentivize to liquidate undercollateralized accounts
    Monetary.Value minBorrowedValue;
  }

  // The maximum RiskParam values that can be set
  struct RiskLimits {
    uint64 marginRatioMax;
    uint64 liquidationSpreadMax;
    uint64 earningsRateMax;
    uint64 marginPremiumMax;
    uint64 spreadPremiumMax;
    uint128 minBorrowedValueMax;
  }

  // The entire storage state of Solo
  struct State {
    // number of markets
    uint numMarkets;
    // marketId => Market
    mapping(uint => Market) markets;
    // owner => account number => Account
    mapping(address => mapping(uint => Account.accStorage)) accounts;
    // Addresses that can control other users accounts
    mapping(address => mapping(address => bool)) operators;
    // Addresses that can control all users accounts
    mapping(address => bool) globalOperators;
    // mutable risk parameters of the system
    RiskParams riskParams;
    // immutable risk limits of the system
    RiskLimits riskLimits;
  }
}

library Types {
  enum AssetDenomination {
    Wei, // the amount is denominated in wei
    Par // the amount is denominated in par
  }

  enum AssetReference {
    Delta, // the amount is given as a delta from the current value
    Target // the amount is given as an exact number to end up at
  }

  struct AssetAmount {
    bool sign; // true if positive
    AssetDenomination denomination;
    AssetReference ref;
    uint value;
  }

  struct TotalPar {
    uint128 borrow;
    uint128 supply;
  }

  struct Par {
    bool sign; // true if positive
    uint128 value;
  }

  struct Wei {
    bool sign; // true if positive
    uint value;
  }
}

interface ISoloMargin {
  struct OperatorArg {
    address operator;
    bool trusted;
  }

  function ownerSetSpreadPremium(uint marketId, Decimal.D256 calldata spreadPremium)
    external;

  function getIsGlobalOperator(address operator) external view returns (bool);

  function getMarketTokenAddress(uint marketId) external view returns (address);

  function ownerSetInterestSetter(uint marketId, address interestSetter) external;

  function getAccountValues(Account.Info calldata account)
    external
    view
    returns (Monetary.Value memory, Monetary.Value memory);

  function getMarketPriceOracle(uint marketId) external view returns (address);

  function getMarketInterestSetter(uint marketId) external view returns (address);

  function getMarketSpreadPremium(uint marketId)
    external
    view
    returns (Decimal.D256 memory);

  function getNumMarkets() external view returns (uint);

  function ownerWithdrawUnsupportedTokens(address token, address recipient)
    external
    returns (uint);

  function ownerSetMinBorrowedValue(Monetary.Value calldata minBorrowedValue) external;

  function ownerSetLiquidationSpread(Decimal.D256 calldata spread) external;

  function ownerSetEarningsRate(Decimal.D256 calldata earningsRate) external;

  function getIsLocalOperator(address _owner, address operator)
    external
    view
    returns (bool);

  function getAccountPar(Account.Info calldata account, uint marketId)
    external
    view
    returns (Types.Par memory);

  function ownerSetMarginPremium(uint marketId, Decimal.D256 calldata marginPremium)
    external;

  function getMarginRatio() external view returns (Decimal.D256 memory);

  function getMarketCurrentIndex(uint marketId)
    external
    view
    returns (Interest.Index memory);

  function getMarketIsClosing(uint marketId) external view returns (bool);

  function getRiskParams() external view returns (Storage.RiskParams memory);

  function getAccountBalances(Account.Info calldata account)
    external
    view
    returns (
      address[] memory,
      Types.Par[] memory,
      Types.Wei[] memory
    );

  function renounceOwnership() external;

  function getMinBorrowedValue() external view returns (Monetary.Value memory);

  function setOperators(OperatorArg[] calldata args) external;

  function getMarketPrice(uint marketId) external view returns (address);

  function owner() external view returns (address);

  function isOwner() external view returns (bool);

  function ownerWithdrawExcessTokens(uint marketId, address recipient)
    external
    returns (uint);

  function ownerAddMarket(
    address token,
    address priceOracle,
    address interestSetter,
    Decimal.D256 calldata marginPremium,
    Decimal.D256 calldata spreadPremium
  ) external;

  function operate(
    Account.Info[] calldata accounts,
    Actions.ActionArgs[] calldata actions
  ) external;

  function getMarketWithInfo(uint marketId)
    external
    view
    returns (
      Storage.Market memory,
      Interest.Index memory,
      Monetary.Price memory,
      Interest.Rate memory
    );

  function ownerSetMarginRatio(Decimal.D256 calldata ratio) external;

  function getLiquidationSpread() external view returns (Decimal.D256 memory);

  function getAccountWei(Account.Info calldata account, uint marketId)
    external
    view
    returns (Types.Wei memory);

  function getMarketTotalPar(uint marketId)
    external
    view
    returns (Types.TotalPar memory);

  function getLiquidationSpreadForPair(uint heldMarketId, uint owedMarketId)
    external
    view
    returns (Decimal.D256 memory);

  function getNumExcessTokens(uint marketId) external view returns (Types.Wei memory);

  function getMarketCachedIndex(uint marketId)
    external
    view
    returns (Interest.Index memory);

  function getAccountStatus(Account.Info calldata account)
    external
    view
    returns (uint8);

  function getEarningsRate() external view returns (Decimal.D256 memory);

  function ownerSetPriceOracle(uint marketId, address priceOracle) external;

  function getRiskLimits() external view returns (Storage.RiskLimits memory);

  function getMarket(uint marketId) external view returns (Storage.Market memory);

  function ownerSetIsClosing(uint marketId, bool isClosing) external;

  function ownerSetGlobalOperator(address operator, bool approved) external;

  function transferOwnership(address newOwner) external;

  function getAdjustedAccountValues(Account.Info calldata account)
    external
    view
    returns (Monetary.Value memory, Monetary.Value memory);

  function getMarketMarginPremium(uint marketId)
    external
    view
    returns (Decimal.D256 memory);

  function getMarketInterestRate(uint marketId)
    external
    view
    returns (Interest.Rate memory);
}
contract DydxFlashloanBase {
  using SafeMath for uint;
  // -- Internal Helper functions -- //
  function _getMarketIdFromTokenAddress(address _solo, address token)
    internal
    view
    returns (uint){
    ISoloMargin solo = ISoloMargin(_solo);

    uint numMarkets = solo.getNumMarkets();

    address curToken;
    for (uint i = 0; i < numMarkets; i++) {
      curToken = solo.getMarketTokenAddress(i);

      if (curToken == token) {
        return i;
      }
    }

    revert("No marketId found for provided token");
  }

  function _getRepaymentAmountInternal(uint amount) internal pure returns (uint) {
    // Needs to be overcollateralize
    // Needs to provide +2 wei to be safe
    return amount.add(2);
  }

  function _getAccountInfo() internal view returns (Account.Info memory) {
    return Account.Info({owner: address(this), number: 1});
  }

  function _getWithdrawAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory){
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Withdraw,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }

  function _getCallAction(bytes memory data)
    internal
    view
    returns (Actions.ActionArgs memory){
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Call,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: 0
        }),
        primaryMarketId: 0,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: data
      });
  }

  function _getDepositAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory){
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Deposit,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: true,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }
}