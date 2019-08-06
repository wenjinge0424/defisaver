pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";

contract SavingsProxy {

    enum SavingsProtocol { Compound, Dydx, Fulcrum }

    mapping(bytes32 => address) public protocols;

    constructor(address _compoundProtocol, address _dydxProtocol, address _fulcrumProtocol) public {
        protocols[getKeyValue(SavingsProtocol.Compound)] = _compoundProtocol;
        protocols[getKeyValue(SavingsProtocol.Dydx)] = _dydxProtocol;
        protocols[getKeyValue(SavingsProtocol.Fulcrum)] = _fulcrumProtocol;
    }

    function deposit(SavingsProtocol _protocol, uint _amount) public {
        ProtocolInterface(protocols[getKeyValue(_protocol)]).deposit(msg.sender, _amount);
    }

    function withdraw(SavingsProtocol _protocol, uint _amount) public {
        ProtocolInterface(protocols[getKeyValue(_protocol)]).withdraw(msg.sender, _amount);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) public {
        ProtocolInterface(protocols[getKeyValue(_from)]).withdraw(msg.sender, _amount);
        ProtocolInterface(protocols[getKeyValue(_to)]).deposit(msg.sender, _amount);
    }

    function getKeyValue(SavingsProtocol _protocol) public view returns(bytes32) {
        return keccak256(abi.encodePacked(_protocol));
    }
}
