pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "./lib/Actions.sol";
import "./lib/Account.sol";
import "./lib/Types.sol";
import "../../interfaces/ERC20.sol";

contract ISoloMargin {
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public;
}

contract DydxProtocol is ProtocolInterface {

    ISoloMargin public soloMargin;
    ERC20 public dai;

    constructor(address _soloMargin, address _daiAddress) public {
        soloMargin = ISoloMargin(_soloMargin);
        dai = ERC20(_daiAddress);
        dai.approve(address(soloMargin), uint(-1));
    }

    function deposit(address _user, uint _amount) public {
        require(dai.transferFrom(_user, address(this), _amount));

        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info({
            owner: address(this),
            number: 0
        });

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        Types.AssetAmount memory amount = Types.AssetAmount({
            sign: true,
            denomination: Types.AssetDenomination.Wei,
            ref: Types.AssetReference.Delta,
            value: _amount
        });

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: amount,
            primaryMarketId: 1, //dai market id
            otherAddress: address(this),
            secondaryMarketId: 0, //not used
            otherAccountId: 0, //not used
            data: "" //not used
        });

        soloMargin.operate(accounts, actions);
    }

    function withdraw(address _user, uint _amount) public {

    }
}
