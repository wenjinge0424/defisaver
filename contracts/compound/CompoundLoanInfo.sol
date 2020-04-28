pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ComptrollerInterface.sol";
import "../interfaces/CTokenInterface.sol";
import "./helpers/Exponential.sol";
import "./helpers/CompoundSaverHelper.sol";

/// @title Gets data about Compound positions
contract CompoundLoanInfo is Exponential, CompoundSaverHelper {
    // solhint-disable-next-line const-name-snakecase
    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    // solhint-disable-next-line const-name-snakecase
    CompoundOracleInterface public constant oracle = CompoundOracleInterface(0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd);

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint[] collAmounts;
        uint[] borrowAmounts;
    }

    struct TokenInfo {
        address cTokenAddress;
        address underlyingTokenAddress;
        uint collateralFactor;
        uint price;
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _user Address of the user
    /// @return Ratio
    function getRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        address[] memory assets = comp.getAssetsIn(_user);

        uint sumCollateral = 0;
        uint sumBorrow = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: oracle.getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Eth
            if (cTokenBalance != 0) {
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
                (, Exp memory tokensToEther) = mulExp(exchangeRate, oraclePrice);
                (, sumCollateral) = mulScalarTruncateAddUInt(tokensToEther, cTokenBalance, sumCollateral);
            }

            // Sum up debt in Eth
            if (borrowBalance != 0) {
                (, sumBorrow) = mulScalarTruncateAddUInt(oraclePrice, borrowBalance, sumBorrow);
            }
        }

        if (sumBorrow == 0) return 0;

        return (sumCollateral * 10**18) / sumBorrow;
    }

    /// @notice Fetches Compound prices for tokens
    /// @param _cTokens Arr. of cTokens for which to get the prices
    /// @return prices Array of prices
    function getPrices(address[] memory _cTokens) public view returns (uint[] memory prices) {
        prices = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; ++i) {
            prices[i] = oracle.getUnderlyingPrice(_cTokens[i]);
        }
    }

    /// @notice Fetches Compound collateral factors for tokens
    /// @param _cTokens Arr. of cTokens for which to get the coll. factors
    /// @return collFactors Array of coll. factors
    function getCollFactors(address[] memory _cTokens) public view returns (uint[] memory collFactors) {
        collFactors = new uint[](_cTokens.length);

        for (uint i = 0; i < _cTokens.length; ++i) {
            (, collFactors[i]) = comp.markets(_cTokens[i]);
        }
    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _user Address of the user
    /// @return LoanData information
    function getLoanData(address _user) public view returns (LoanData memory data) {
        address[] memory assets = comp.getAssetsIn(_user);

        data = LoanData({
            user: _user,
            ratio: 0,
            collAddr: new address[](assets.length),
            borrowAddr: new address[](assets.length),
            collAmounts: new uint[](assets.length),
            borrowAmounts: new uint[](assets.length)
        });

        uint sumCollateral = 0;
        uint sumBorrow = 0;
        uint collPos = 0;
        uint borrowPos = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CTokenInterface(asset).getAccountSnapshot(_user);

            Exp memory oraclePrice;

            if (cTokenBalance != 0 || borrowBalance != 0) {
                oraclePrice = Exp({mantissa: oracle.getUnderlyingPrice(asset)});
            }

            // Sum up collateral in Eth
            if (cTokenBalance != 0) {
                Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
                (, Exp memory tokensToEther) = mulExp(exchangeRate, oraclePrice);
                (, sumCollateral) = mulScalarTruncateAddUInt(tokensToEther, cTokenBalance, sumCollateral);

                data.collAddr[collPos] = asset;
                (, data.collAmounts[collPos]) = mulScalarTruncate(tokensToEther, cTokenBalance);
                collPos++;
            }

            // Sum up debt in Eth
            if (borrowBalance != 0) {
                (, sumBorrow) = mulScalarTruncateAddUInt(oraclePrice, borrowBalance, sumBorrow);

                data.borrowAddr[borrowPos] = asset;
                (, data.borrowAmounts[borrowPos]) = mulScalarTruncate(oraclePrice, borrowBalance);
                borrowPos++;
            }
        }

        if (sumBorrow == 0) return data;

        data.ratio = uint128((sumCollateral * 10**18) / sumBorrow);

    }

    /// @notice Fetches all the collateral/debt address and amounts, denominated in ether
    /// @param _users Addresses of the user
    /// @return Array of LoanData information
    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }

    /// @notice Calcualted the ratio of coll/debt for a compound user
    /// @param _users Addresses of the user
    /// @return Array of ratios
    function getRatios(address[] memory _users) public view returns (uint[] memory ratios) {
        ratios = new uint[](_users.length);

        for (uint i = 0; i < _users.length; ++i) {
            ratios[i] = getRatio(_users[i]);
        }
    }

    /// @notice Information about cTokens
    /// @param _cTokenAddresses Array of cTokens addresses
    /// @return Array of cTokens infomartion
    function getTokensInfo(address[] memory _cTokenAddresses) public returns(TokenInfo[] memory tokens) {
        tokens = new TokenInfo[](_cTokenAddresses.length);

        for (uint i = 0; i < _cTokenAddresses.length; ++i) {
            (, uint collFactor) = comp.markets(_cTokenAddresses[i]);

            tokens[i] = TokenInfo({
                cTokenAddress: _cTokenAddresses[i],
                underlyingTokenAddress: getUnderlyingAddr(_cTokenAddresses[i]),
                collateralFactor: collFactor,
                price: oracle.getUnderlyingPrice(_cTokenAddresses[i])
            });
        }
    }
}
