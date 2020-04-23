pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./helpers/Exponential.sol";
import "./helpers/ComptrollerInterface.sol";

contract CToken {
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

contract CompoundOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}


contract CompoundLoanInfo is Exponential {
    // solhint-disable-next-line const-name-snakecase
    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    // solhint-disable-next-line const-name-snakecase
    CompoundOracle public constant oracle = CompoundOracle(0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd);

    struct LoanData {
        address user;
        uint128 ratio;
        address[] collAddr;
        address[] borrowAddr;
        uint[] collAmounts;
        uint[] borrowAmounts;
    }

    function getRatio(address _user) public view returns (uint) {
        // For each asset the account is in
        address[] memory assets = comp.getAssetsIn(_user);

        uint sumCollateral = 0;
        uint sumBorrow = 0;

        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            (, uint cTokenBalance, uint borrowBalance, uint exchangeRateMantissa)
                                        = CToken(asset).getAccountSnapshot(_user);

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

    function getPrices(address[] memory _cTokens) public view returns (uint[] memory prices) {
        prices = new uint[](_cTokens.length);
        
        for (uint i = 0; i < _cTokens.length; ++i) {
            prices[i] = oracle.getUnderlyingPrice(_cTokens[i]);
        }
    }

    function getCollFactors(address[] memory _cTokens) public view returns (uint[] memory collFactors) {
        collFactors = new uint[](_cTokens.length);
        
        for (uint i = 0; i < _cTokens.length; ++i) {
            (, collFactors[i]) = comp.markets(_cTokens[i]);
        }
    }

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
                                        = CToken(asset).getAccountSnapshot(_user);

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

    function getLoanDataArr(address[] memory _users) public view returns (LoanData[] memory loans) {
        loans = new LoanData[](_users.length);
        
        for (uint i = 0; i < _users.length; ++i) {
            loans[i] = getLoanData(_users[i]);
        }
    }

    function getRatios(address[] memory _users) public view returns (uint[] memory ratios) {
        ratios = new uint[](_users.length);
        
        for (uint i = 0; i < _users.length; ++i) {
            ratios[i] = getRatio(_users[i]);
        }
    }
}
