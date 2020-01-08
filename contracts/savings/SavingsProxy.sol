pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/ITokenInterface.sol";
import "../constants/ConstantAddresses.sol";
import "./dydx/ISoloMargin.sol";
import "./SavingsLogger.sol";
import "./dsr/DSRSavingsProtocol.sol";

contract SavingsProxy is ConstantAddresses, DSRSavingsProtocol {

    address constant public SAVINGS_COMPOUND_ADDRESS = 0x72c5a18D651DA5568EFfE731a98484dE62C9F347;
    address constant public SAVINGS_DYDX_ADDRESS = 0x03b1565e070df392e48e7a8e01798C4B00E534A5;
    address constant public SAVINGS_FULCRUM_ADDRESS = 0xe9ea575d2d8Ca26b0E026a2146994592e0Ee1Dd9;

    enum SavingsProtocol { Compound, Dydx, Fulcrum, Dsr }

    function deposit(SavingsProtocol _protocol, uint _amount) public {
        if (_protocol == SavingsProtocol.Dsr) {
            dsrDeposit(_amount);
        } else {
            _deposit(_protocol, _amount);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logDeposit(msg.sender, uint8(_protocol), _amount);
    }

    function withdraw(SavingsProtocol _protocol, uint _amount) public {
        if (_protocol == SavingsProtocol.Dsr) {
            dsrWithdraw(_amount);
        } else {
            _withdraw(_protocol, _amount);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logWithdraw(msg.sender, uint8(_protocol), _amount);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) public {
        if (_from == SavingsProtocol.Dsr) {
            dsrWithdraw(_amount);
        } else {
            _withdraw(_from, _amount);
        }

        if (_to == SavingsProtocol.Dsr) {
            dsrDeposit(_amount);
        } else {
            _deposit(_to, _amount);
        }

        SavingsLogger(SAVINGS_LOGGER_ADDRESS).logSwap(msg.sender, uint8(_from), uint8(_to), _amount);
    }


    function withdrawDai() public {
        ERC20(DAI_ADDRESS).transfer(msg.sender, ERC20(DAI_ADDRESS).balanceOf(address(this)));
    }

    function getAddress(SavingsProtocol _protocol) public pure returns(address) {
        if (_protocol == SavingsProtocol.Compound) {
            return SAVINGS_COMPOUND_ADDRESS;
        }

        if (_protocol == SavingsProtocol.Dydx) {
            return SAVINGS_DYDX_ADDRESS;
        }

        if (_protocol == SavingsProtocol.Fulcrum) {
            return SAVINGS_FULCRUM_ADDRESS;
        }
    }

    function _deposit(SavingsProtocol _protocol, uint _amount) internal {
        approveDeposit(_protocol, _amount);

        ProtocolInterface(getAddress(_protocol)).deposit(address(this), _amount);

        endAction(_protocol);
    }

    function _withdraw(SavingsProtocol _protocol, uint _amount) public {
        approveWithdraw(_protocol, _amount);

        ProtocolInterface(getAddress(_protocol)).withdraw(address(this), _amount);

        endAction(_protocol);

        withdrawDai();
    }

    function endAction(SavingsProtocol _protocol) internal {
        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(false);
        }
    }

    function approveDeposit(SavingsProtocol _protocol, uint _amount) internal {
        ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);

        if (_protocol == SavingsProtocol.Compound || _protocol == SavingsProtocol.Fulcrum) {
            ERC20(DAI_ADDRESS).approve(getAddress(_protocol), uint(-1));
        }

        if (_protocol == SavingsProtocol.Dydx) {
            ERC20(DAI_ADDRESS).approve(SOLO_MARGIN_ADDRESS, uint(-1));
            setDydxOperator(true);
        }
    }

    function approveWithdraw(SavingsProtocol _protocol, uint _amount) internal {
        if (_protocol == SavingsProtocol.Compound) {
            ERC20(NEW_CDAI_ADDRESS).approve(getAddress(_protocol), uint(-1));
        }

        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(true);
        }

        if (_protocol == SavingsProtocol.Fulcrum) {
            ERC20(NEW_IDAI_ADDRESS).approve(getAddress(_protocol), uint(-1));
        }
    }

    function setDydxOperator(bool _trusted) internal {
        ISoloMargin.OperatorArg[] memory operatorArgs = new ISoloMargin.OperatorArg[](1);
        operatorArgs[0] = ISoloMargin.OperatorArg({
            operator: getAddress(SavingsProtocol.Dydx),
            trusted: _trusted
        });

        ISoloMargin(SOLO_MARGIN_ADDRESS).setOperators(operatorArgs);
    }
}
