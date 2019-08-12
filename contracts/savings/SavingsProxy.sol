pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";

contract SavingsProxy {

    enum SavingsProtocol { Compound, Dydx, Fulcrum }

    mapping(bytes32 => address) public protocols;

    function addProtocols(address _compoundProtocol, address _dydxProtocol, address _fulcrumProtocol) public {
        // allow setting only once
        require(protocols[getKeyValue(SavingsProtocol.Compound)] == address(0));

        protocols[getKey(SavingsProtocol.Compound)] = _compoundProtocol;
        protocols[getKey(SavingsProtocol.Dydx)] = _dydxProtocol;
        protocols[getKey(SavingsProtocol.Fulcrum)] = _fulcrumProtocol;
    }

    function deposit(SavingsProtocol _protocol, uint _amount) public {
        ProtocolInterface(protocols[getKey(_protocol)]).deposit(msg.sender, _amount);
    }

    function withdraw(SavingsProtocol _protocol, uint _amount) public {
        ProtocolInterface(protocols[getKey(_protocol)]).withdraw(msg.sender, _amount);
    }

    function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) public {
        ProtocolInterface(protocols[getKey(_from)]).withdraw(msg.sender, _amount);
        ProtocolInterface(protocols[getKey(_to)]).deposit(msg.sender, _amount);
    }

    function getKey(SavingsProtocol _protocol) public view returns(bytes32) {
        return keccak256(abi.encodePacked(_protocol));
    }
}
