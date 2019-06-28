pragma solidity ^0.5.0;

import "../DS/DSMath.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/TubInterface.sol";
import "../interfaces/KyberNetworkProxyInterface.sol";
import "../ActionLogger.sol";
import "./Exponential.sol";

/// @title Used only on kovan as a helper because different Dai tokens are used in Maker | Compound
contract StupidExchange {
    address public constant MAKER_DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant COMPOUND_DAI_ADDRESS = 0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD;
    
    function getMakerDaiToken(uint _amount) public {
        ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, _amount);
    }
    
    function getCompoundDaiToken(uint _amount) public {
        ERC20(COMPOUND_DAI_ADDRESS).transfer(msg.sender, _amount);
    }
}

/// @title CompoundProxy implements CDP and Compound direct interactions
contract CompoundProxy is DSMath, Exponential {
    
    // Kovan addresses
    address public constant TUB_ADDRESS = 0xa71937147b55Deb8a530C7229C442Fd3F31b7db2;
    address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public constant DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant MKR_ADDRESS = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;
    address public constant PETH_ADDRESS = 0xf4d791139cE033Ad35DB2B2201435fAd668B1b64;
    address public constant KYBER_WRAPPER = 0x82CD6436c58A65E2D4263259EcA5843d3d7e0e65;
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CDAI_ADDRESS = 0xb6b09fBffBa6A5C4631e5F7B2e3Ee183aC259c0d;
    address public constant LOGGER_ADDRESS = 0x70b742b84a75aFF6482953f7883Fd7E70d3dBbac;
    address public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;
    address public constant KYBER_INTERFACE = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    address public constant COMPOUND_DAI_ADDRESS = 0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD;
    address public constant STUPID_EXCHANGE = 0x863E41FE88288ebf3fcd91d8Dbb679fb83fdfE17;
    
    /// @notice It will draw Dai from Compound and repay part of the CDP debt
    /// @dev User has to approve DSProxy to pull CDai before calling this
    /// @param _cup Cdp id
    /// @param _amount Amount of Dai that will be taken from Compound and put into CDP
    function repayCDPDebt(bytes32 _cup, uint _amount) public {
        TubInterface tub = TubInterface(TUB_ADDRESS);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);
        
        approveTub(DAI_ADDRESS);
        approveTub(MKR_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(WETH_ADDRESS);

        // Calculate how many cDai tokens we need to pull for the Dai _amount
        uint cAmount = getCTokenAmount(_amount, CDAI_ADDRESS);     

        cDaiContract.approve(CDAI_ADDRESS, uint(-1));
        cDaiContract.transferFrom(msg.sender, address(this), cAmount);
        
        require(cDaiContract.redeemUnderlying(_amount) == 0, "Reedem Failed");
        
        // REMOVE: USED ONLY ON KOVAN TO HANDLE DAI DIFFERENT TOKENS
        StupidExchange(STUPID_EXCHANGE).getMakerDaiToken(_amount);

        // Buy some Mkr to pay stability fee
        uint mkrAmount = stabilityFeeInMkr(tub, _cup, _amount);
        uint daiFee = wdiv(mkrAmount, estimatedDaiMkrPrice(_amount));
        uint amountExchanged = exchangeToken(ERC20(DAI_ADDRESS), ERC20(MKR_ADDRESS), daiFee, mkrAmount);

        _amount = sub(_amount, daiFee);

        uint daiDebt = getDebt(tub, _cup);

        if (_amount > daiDebt) {
            ERC20(DAI_ADDRESS).transfer(msg.sender, sub(_amount, daiDebt));
            _amount = daiDebt;
        }
        
        tub.wipe(_cup, _amount);

        ERC20(MKR_ADDRESS).transfer(msg.sender, ERC20(MKR_ADDRESS).balanceOf(address(this)));
        ActionLogger(LOGGER_ADDRESS).logEvent('repayCDPDebt', msg.sender, mkrAmount, amountExchanged);
    }
    
    /// @notice It will draw Dai from CDP and add it to Compound
    /// @param _cup CDP id
    /// @param _amount Amount of Dai drawn from the CDP and put into Compound
    function cdpToCompound(bytes32 _cup, uint _amount) public {
        TubInterface tub = TubInterface(TUB_ADDRESS);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);

        approveTub(WETH_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(DAI_ADDRESS);

        tub.draw(_cup, _amount);
        
        StupidExchange(STUPID_EXCHANGE).getCompoundDaiToken(_amount);
        
        //cDai will try and pull Dai tokens from DSProxy, so approve it
        ERC20(COMPOUND_DAI_ADDRESS).approve(CDAI_ADDRESS, uint(-1));
        
        require(cDaiContract.mint(_amount) == 0, "Failed Mint");
        
        uint cDaiMinted = cDaiContract.balanceOf(address(this));
        
        // transfer the cDai to the original sender
        ERC20(CDAI_ADDRESS).transfer(msg.sender, cDaiMinted);
        
        ActionLogger(LOGGER_ADDRESS).logEvent('cdpToCompound', msg.sender, _amount, cDaiMinted);
        
    }

    /// @notice Calculates how many cTokens you get for a _tokenAmount
    function getCTokenAmount(uint _tokenAmount, address _tokeAddress) internal returns(uint cAmount) {
        MathError error;
        (error, cAmount) = divScalarByExpTruncate(_tokenAmount,
             Exp({mantissa: CTokenInterface(_tokeAddress).exchangeRateCurrent()}));

        require(error == MathError.NO_ERROR, "Math error");
    }
    
    /// @notice Stability fee amount in Mkr
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiRepay Amount of dai we are repaying
    function stabilityFeeInMkr(TubInterface _tub, bytes32 _cup, uint _daiRepay) public returns (uint) {
        bytes32 mkrPrice;
        bool ok;

        uint feeInDai = rmul(_daiRepay, rdiv(_tub.rap(_cup), _tub.tab(_cup)));

        (mkrPrice, ok) = _tub.pep().peek();

        return wdiv(feeInDai, uint(mkrPrice));
    }
    
    /// @notice Returns expected rate for Dai -> Mkr conversion
    /// @param _daiAmount Amount of Dai
    function estimatedDaiMkrPrice(uint _daiAmount) internal returns (uint expectedRate) {
        (expectedRate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE).getExpectedRate(ERC20(DAI_ADDRESS), ERC20(MKR_ADDRESS), _daiAmount);
    }
    
    /// @notice Approve a token if it's not already approved
    /// @param _tokenAddress Address of the ERC20 token we want to approve
    function approveTub(address _tokenAddress) internal {
        if (ERC20(_tokenAddress).allowance(msg.sender, _tokenAddress) < (uint(-1) / 2)) {
            ERC20(_tokenAddress).approve(TUB_ADDRESS, uint(-1));
        }
    }

    /// @notice Returns current Dai debt of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getDebt(TubInterface _tub, bytes32 _cup) internal returns (uint debt) {
        ( , , debt, ) = _tub.cups(_cup);
    }

    /// @notice Exhcanged a token on kyber
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
            address(this),
            _maxAmount,
            minRate,
            WALLET_ID
        );
    }
}