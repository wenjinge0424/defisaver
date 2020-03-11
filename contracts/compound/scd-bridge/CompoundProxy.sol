pragma solidity ^0.5.0;

import "../../DS/DSMath.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/TubInterface.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../loggers/ActionLogger.sol";
import "../helpers/Exponential.sol";
import "../helpers/StupidExchange.sol";
import "../../constants/ConstantAddresses.sol";


/// @title CompoundProxy implements CDP and Compound direct interactions
contract CompoundProxy is DSMath, Exponential, ConstantAddresses {
    /// @notice It will draw Dai from Compound and repay part of the CDP debt
    /// @dev User has to approve DSProxy to pull CDai before calling this
    /// @param _cup Cdp id
    /// @param _amount Amount of Dai that will be taken from Compound and put into CDP
    function repayCDPDebt(bytes32 _cup, uint256 _amount) public {
        TubInterface tub = TubInterface(TUB_ADDRESS);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);

        approveTub(MAKER_DAI_ADDRESS);
        approveTub(MKR_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(WETH_ADDRESS);

        // Calculate how many cDai tokens we need to pull for the Dai _amount
        uint256 cAmount = getCTokenAmount(_amount, CDAI_ADDRESS);

        cDaiContract.approve(CDAI_ADDRESS, uint256(-1));
        cDaiContract.transferFrom(msg.sender, address(this), cAmount);

        require(cDaiContract.redeemUnderlying(_amount) == 0, "Reedem Failed");

        // REMOVE: USED ONLY ON KOVAN TO HANDLE DAI DIFFERENT TOKENS
        StupidExchange(STUPID_EXCHANGE).getMakerDaiToken(_amount);

        // Buy some Mkr to pay stability fee
        uint256 mkrAmount = stabilityFeeInMkr(tub, _cup, _amount);
        uint256 daiFee = wdiv(mkrAmount, estimatedDaiMkrPrice(_amount));
        uint256 amountExchanged = exchangeToken(
            ERC20(MAKER_DAI_ADDRESS),
            ERC20(MKR_ADDRESS),
            daiFee,
            mkrAmount
        );

        _amount = sub(_amount, daiFee);

        uint256 daiDebt = getDebt(tub, _cup);

        if (_amount > daiDebt) {
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, sub(_amount, daiDebt));
            _amount = daiDebt;
        }

        tub.wipe(_cup, _amount);

        ERC20(MKR_ADDRESS).transfer(msg.sender, ERC20(MKR_ADDRESS).balanceOf(address(this)));
        ActionLogger(LOGGER_ADDRESS).logEvent(
            "repayCDPDebt",
            msg.sender,
            mkrAmount,
            amountExchanged
        );
    }

    /// @notice It will draw Dai from CDP and add it to Compound
    /// @param _cup CDP id
    /// @param _amount Amount of Dai drawn from the CDP and put into Compound
    function cdpToCompound(bytes32 _cup, uint256 _amount) public {
        TubInterface tub = TubInterface(TUB_ADDRESS);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);

        approveTub(WETH_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(MAKER_DAI_ADDRESS);

        tub.draw(_cup, _amount);

        StupidExchange(STUPID_EXCHANGE).getCompoundDaiToken(_amount);

        //cDai will try and pull Dai tokens from DSProxy, so approve it
        ERC20(COMPOUND_DAI_ADDRESS).approve(CDAI_ADDRESS, uint256(-1));

        require(cDaiContract.mint(_amount) == 0, "Failed Mint");

        uint256 cDaiMinted = cDaiContract.balanceOf(address(this));

        // transfer the cDai to the original sender
        ERC20(CDAI_ADDRESS).transfer(msg.sender, cDaiMinted);

        ActionLogger(LOGGER_ADDRESS).logEvent("cdpToCompound", msg.sender, _amount, cDaiMinted);
    }

    /// @notice Calculates how many cTokens you get for a _tokenAmount
    function getCTokenAmount(uint256 _tokenAmount, address _tokeAddress)
        internal
        returns (uint256 cAmount)
    {
        MathError error;
        (error, cAmount) = divScalarByExpTruncate(
            _tokenAmount,
            Exp({mantissa: CTokenInterface(_tokeAddress).exchangeRateCurrent()})
        );

        require(error == MathError.NO_ERROR, "Math error");
    }

    /// @notice Stability fee amount in Mkr
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiRepay Amount of dai we are repaying
    function stabilityFeeInMkr(TubInterface _tub, bytes32 _cup, uint256 _daiRepay)
        public
        returns (uint256)
    {
        bytes32 mkrPrice;
        bool ok;

        uint256 feeInDai = rmul(_daiRepay, rdiv(_tub.rap(_cup), _tub.tab(_cup)));

        (mkrPrice, ok) = _tub.pep().peek();

        return wdiv(feeInDai, uint256(mkrPrice));
    }

    /// @notice Returns expected rate for Dai -> Mkr conversion
    /// @param _daiAmount Amount of Dai
    function estimatedDaiMkrPrice(uint256 _daiAmount) internal returns (uint256 expectedRate) {
        (expectedRate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE).getExpectedRate(
            ERC20(MAKER_DAI_ADDRESS),
            ERC20(MKR_ADDRESS),
            _daiAmount
        );
    }

    /// @notice Approve a token if it's not already approved
    /// @param _tokenAddress Address of the ERC20 token we want to approve
    function approveTub(address _tokenAddress) internal {
        if (ERC20(_tokenAddress).allowance(msg.sender, _tokenAddress) < (uint256(-1) / 2)) {
            ERC20(_tokenAddress).approve(TUB_ADDRESS, uint256(-1));
        }
    }

    /// @notice Returns current Dai debt of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getDebt(TubInterface _tub, bytes32 _cup) internal returns (uint256 debt) {
        (, , debt, ) = _tub.cups(_cup);
    }

    /// @notice Exhcanged a token on kyber
    function exchangeToken(
        ERC20 _sourceToken,
        ERC20 _destToken,
        uint256 _sourceAmount,
        uint256 _maxAmount
    ) internal returns (uint256 destAmount) {
        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        uint256 minRate;
        (, minRate) = _kyberNetworkProxy.getExpectedRate(_sourceToken, _destToken, _sourceAmount);

        require(_sourceToken.approve(address(_kyberNetworkProxy), 0));
        require(_sourceToken.approve(address(_kyberNetworkProxy), _sourceAmount));

        destAmount = _kyberNetworkProxy.trade(
            _sourceToken,
            _sourceAmount,
            _destToken,
            address(this),
            _maxAmount,
            minRate,
            WALLET_ID
        );
    }
}
