pragma solidity ^0.5.0;

import "../interfaces/TubInterface.sol";
import "../DS/DSGuard.sol";
import "./Marketplace.sol";
import "../constants/ConstantAddresses.sol";

/// @title MarketplaceProxy handles authorization and interaction with the Marketplace contract
contract MarketplaceProxy is ConstantAddresses {

    ///@dev Called by the Marketplace contract, will give CDP only if you're authorized or CDP owner
    ///@param _cup CDP Id
    ///@param _newOwner Transfer the CDP to this address
    function give(bytes32 _cup, address _newOwner) public {
        TubInterface tub = TubInterface(TUB_ADDRESS);

        tub.give(_cup, _newOwner);
    }

    ///@dev Creates a new DSGuard for the user, authorizes the marketplace contract and puts on sale the cdp
    ///@param _cup CDP Id
    ///@param _discount 4 digit number representing a discount of CDP value (0-9999)
    ///@param _marketplace Address of the marketplace contract
    function createAuthorizeAndSell(bytes32 _cup, uint _discount, address _marketplace, address _proxy) public {
        DSGuard guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(_proxy).setAuthority(DSAuthority(address(guard)));

        guard.permit(_marketplace, _proxy, bytes4(keccak256("execute(address,bytes)")));

        Marketplace(_marketplace).putOnSale(_cup, _discount);
    }

    ///@dev If the user already own a DSGuard but isn't authorized, authorizes the marketplace contract and sell
    ///@param _cup CDP Id
    ///@param _discount 4 digit number representing a discount of CDP value (0-9999)
    ///@param _marketplace Address of the marketplace contract
    function authorizeAndSell(bytes32 _cup, uint _discount, address _marketplace, address _proxy) public {
        DSGuard guard = DSGuard(address(DSAuth(_proxy).authority()));
        guard.permit(_marketplace, _proxy, bytes4(keccak256("execute(address,bytes)")));

        Marketplace(_marketplace).putOnSale(_cup, _discount);
    }

    ///@dev Put a cdp on sale, if the user already has a DSGuard and authorized it
    ///@param _cup CDP Id
    ///@param _discount 4 digit number representing a discount of CDP value (0-9999)
    ///@param _marketplace Address of the marketplace contract
    function sell(bytes32 _cup, uint _discount, address _marketplace) public {
        Marketplace(_marketplace).putOnSale(_cup, _discount);
    }

    ///@dev Cancel a CDP on sale
    ///@param _cup CDP Id
    ///@param _marketplace Address of the marketplace contract
    function cancel(bytes32 _cup, address _marketplace) public {
        Marketplace(_marketplace).cancel(_cup);
    }
}
