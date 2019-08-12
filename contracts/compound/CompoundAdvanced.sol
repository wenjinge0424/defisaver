pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "../interfaces/KyberNetworkProxyInterface.sol";
import "./Exponential.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";

contract CompoundAdvanced is Exponential, DSMath, ConstantAddresses {

    /// @notice Takes out an asset which a user supplies, converts and pays the debt
    function repay(address _suppliedAsset, address _borrowedAsset, address _underlyingSupply, address _underlyingBorrow, uint _amount) public {
        CTokenInterface cSuppliedContract = CTokenInterface(_suppliedAsset);
        CTokenInterface cBorrowedContract = CTokenInterface(_borrowedAsset);

        uint cAmount = getCTokenAmount(_amount, _suppliedAsset);

        cSuppliedContract.approve(_suppliedAsset, cAmount);
        cSuppliedContract.transferFrom(msg.sender, address(this), cAmount);

        //TODO: how much can we reedem
        require(cSuppliedContract.redeemUnderlying(_amount) == 0, "Reedem Failed");

        uint borrowAmount = cBorrowedContract.borrowBalanceCurrent(msg.sender);

        //TODO : check this
        uint debtInSupplyToken = wmul(borrowAmount, estimatedSourceTokenPrice(_underlyingSupply, _underlyingBorrow, _amount));

        uint amountExchanged = exchangeToken(ERC20(_underlyingSupply), ERC20(_underlyingBorrow), debtInSupplyToken, borrowAmount);

        require(amountExchanged <= borrowAmount, "Conversion must be precise");

        require(cBorrowedContract.repayBorrowBehalf(msg.sender, amountExchanged) == 0, "Repay Failed");
    }

    function exchangeToken(ERC20 _sourceToken, ERC20 _destToken, uint _sourceAmount, uint _maxAmount) internal returns (uint destAmount) {
        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        uint minRate;
        (, minRate) = _kyberNetworkProxy.getExpectedRate(_sourceToken, _destToken, _sourceAmount);

        require(_sourceToken.approve(address(_kyberNetworkProxy), 0));
        require(_sourceToken.approve(address(_kyberNetworkProxy), _sourceAmount));

        destAmount = _kyberNetworkProxy.trade(
            _sourceToken,
            _sourceAmount,
            _destToken,
            msg.sender,
            _maxAmount,
            minRate,
            WALLET_ID
        );

        return destAmount;
    }

    /// @notice Returns expected rate for Eth -> Dai conversion
    /// @param _amount Amount of Ether
    function estimatedSourceTokenPrice(address _source, address _dest, uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE).getExpectedRate(ERC20(_source), ERC20(_dest), _amount);
    }

    /// @notice Calculates how many cTokens you get for a _tokenAmount
    function getCTokenAmount(uint _tokenAmount, address _tokeAddress) internal returns(uint cAmount) {
        MathError error;
        (error, cAmount) = divScalarByExpTruncate(_tokenAmount,
             Exp({mantissa: CTokenInterface(_tokeAddress).exchangeRateCurrent()}));

        require(error == MathError.NO_ERROR, "Math error");
    }
}
