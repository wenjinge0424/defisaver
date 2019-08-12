pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";
import "../interfaces/ERC20.sol";
import "../constants/ConstantAddresses.sol";
import "./dydx/ISoloMargin.sol";

contract SavingsProxy is ConstantAddresses {

    address constant public SAVINGS_COMPOUND_ADDRESS = 0x5bdF0b2FaF59639f41946EE2DeBa90f0e02EB867;
    address constant public SAVINGS_DYDX_ADDRESS = 0x13903074023f8a269671e12401Cce148eA18784D;
    address constant public SAVINGS_FULCRUM_ADDRESS = 0x560d427777a206E3152B9b2a998aC52a8660269A;

    enum SavingsProtocol { Compound, Dydx, Fulcrum }

    function deposit(SavingsProtocol _protocol, uint _amount) public {
        approveDeposit(_protocol, _amount);

        ProtocolInterface(getAddress(_protocol)).deposit(address(this), _amount);

        endAction(_protocol);
    }

    function withdraw(SavingsProtocol _protocol, uint _amount) public {
        approveWithdraw(_protocol, _amount);

        ProtocolInterface(getAddress(_protocol)).withdraw(address(this), _amount);

        endAction(_protocol);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) public {
        approveWithdraw(_from, _amount);
        approveDeposit(_to, _amount);

        ProtocolInterface(getAddress(_from)).withdraw(address(this), _amount);
        ProtocolInterface(getAddress(_to)).deposit(address(this), _amount);

        endAction(_from);
        endAction(_to);
    }

    function getAddress(SavingsProtocol _protocol) public view returns(address) {
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

    function endAction(SavingsProtocol _protocol)  internal {
        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(false);
        }
    }

    function approveDeposit(SavingsProtocol _protocol, uint _amount) internal {
        ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);

        if (_protocol == SavingsProtocol.Compound || _protocol == SavingsProtocol.Fulcrum) {
            ERC20(MAKER_DAI_ADDRESS).approve(getAddress(_protocol), _amount);
        }

        if (_protocol == SavingsProtocol.Dydx) {
            ERC20(MAKER_DAI_ADDRESS).approve(SOLO_MARGIN_ADDRESS, _amount);
            setDydxOperator(true);
        }
    }

    function approveWithdraw(SavingsProtocol _protocol, uint _amount) internal {
        if (_protocol == SavingsProtocol.Compound) {
            ERC20(CDAI_ADDRESS).approve(getAddress(_protocol), _amount);
        }

        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(true);
        }

        if (_protocol == SavingsProtocol.Fulcrum) {
            ERC20(IDAI_ADDRESS).approve(getAddress(_protocol), _amount);
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
