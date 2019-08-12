pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";
import "../interfaces/ERC20.sol";
import "../constants/ConstantAddresses.sol";
import "./dydx/ISoloMargin.sol";

contract SavingsProxy is ConstantAddresses {

    enum SavingsProtocol { Compound, Dydx, Fulcrum }

    mapping(bytes32 => address) public protocols;

    function addProtocols(address _compoundProtocol, address _dydxProtocol, address _fulcrumProtocol) public {
        // allow setting only once
        require(protocols[getKey(SavingsProtocol.Compound)] == address(0));

        protocols[getKey(SavingsProtocol.Compound)] = _compoundProtocol;
        protocols[getKey(SavingsProtocol.Dydx)] = _dydxProtocol;
        protocols[getKey(SavingsProtocol.Fulcrum)] = _fulcrumProtocol;
    }

    function deposit(SavingsProtocol _protocol, uint _amount) public {
        approveDeposit(_protocol, _amount);

        ProtocolInterface(protocols[getKey(_protocol)]).deposit(address(this), _amount);

        endAction(_protocol);
    }

    function withdraw(SavingsProtocol _protocol, uint _amount) public {
        approveWithdraw(_protocol, _amount);

        ProtocolInterface(protocols[getKey(_protocol)]).withdraw(address(this), _amount);

        endAction(_protocol);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) public {
        approveWithdraw(_from, _amount);
        approveDeposit(_to, _amount);

        ProtocolInterface(protocols[getKey(_from)]).withdraw(address(this), _amount);
        ProtocolInterface(protocols[getKey(_to)]).deposit(address(this), _amount);

        endAction(_from);
        endAction(_to);
    }

    function getKey(SavingsProtocol _protocol) public view returns(bytes32) {
        return keccak256(abi.encodePacked(_protocol));
    }

    function endAction(SavingsProtocol _protocol)  internal {
        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(false);
        }
    }

    function approveDeposit(SavingsProtocol _protocol, uint _amount) internal {
        ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);

        if (_protocol == SavingsProtocol.Compound || _protocol == SavingsProtocol.Fulcrum) {
            ERC20(MAKER_DAI_ADDRESS).approve(protocols[getKey(_protocol)], _amount);
        }

        if (_protocol == SavingsProtocol.Dydx) {
            ERC20(MAKER_DAI_ADDRESS).approve(SOLO_MARGIN_ADDRESS, _amount);
            setDydxOperator(true);
        }
    }

    function approveWithdraw(SavingsProtocol _protocol, uint _amount) internal {
        if (_protocol == SavingsProtocol.Compound) {
            ERC20(CDAI_ADDRESS).approve(protocols[getKey(_protocol)], _amount);
        }

        if (_protocol == SavingsProtocol.Dydx) {
            setDydxOperator(true);
        }

        if (_protocol == SavingsProtocol.Fulcrum) {
            ERC20(IDAI_ADDRESS).approve(protocols[getKey(_protocol)], _amount);
        }
    }

    function setDydxOperator(bool _trusted) internal {
        ISoloMargin.OperatorArg[] memory operatorArgs = new ISoloMargin.OperatorArg[](1);
        operatorArgs[0] = ISoloMargin.OperatorArg({
            operator: protocols[getKey(SavingsProtocol.Dydx)],
            trusted: _trusted
        });

        ISoloMargin(SOLO_MARGIN_ADDRESS).setOperators(operatorArgs);
    }
}
