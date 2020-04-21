pragma solidity ^0.5.0;

import "./helpers/Exponential.sol";
import "./helpers/ComptrollerInterface.sol";

contract CToken {
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

contract CompoundOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

contract CompoundLoanInfo is Exponential {

    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    CompoundOracle public constant oracle = CompoundOracle(0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd);

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
}
