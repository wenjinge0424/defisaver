pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;


import "../../savings/dydx/ISoloMargin.sol";
import "../../interfaces/ERC20.sol";

contract ICallee {
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
    public;
}

contract ReceiverCaller is ICallee {

    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) public {
        address(this).call(data);

    }
}

contract TestLoan is ReceiverCaller {

    event LoanReceived(uint _amount);

    address public constant FLASH_LOAN_TOKEN = 0xad7B3C18edeA34D8091295991373C310278d8920;

    function takeLoan(address _tokenAddr, uint _borrowAmount) public {
        FlashTokenDyDx(FLASH_LOAN_TOKEN).flashBorrow(
            _tokenAddr,
            _borrowAmount,
            address(this),
            abi.encodeWithSignature("loanReceiver(address,uint256)", _borrowAmount)
        );
    }

    function loanReceiver(address _tokenAddr, uint _amount) public {

        // do sumting

        ERC20(_tokenAddr).transfer(FLASH_LOAN_TOKEN, _amount);

        emit LoanReceived(_amount);


    }
}

contract FlashTokenDyDx {

    ISoloMargin public soloMargin;

    uint daiMarketId = 3;

    address public constant SOLO_MARGIN_ADDRESS = 0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE;

    constructor() public {
        soloMargin = ISoloMargin(SOLO_MARGIN_ADDRESS);
    }

    function flashBorrow(
        address _tokenAddr,
        uint _borrowAmount,
        address _receiver,
        bytes calldata _funcData
    ) external {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = getAccount(_receiver, 0);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](3);

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: getAssetAmount(_borrowAmount),
            primaryMarketId: daiMarketId,
            otherAddress: _receiver,
            secondaryMarketId: 0,
            otherAccountId: 0,
            data: ""
        });

        actions[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.Call,
            accountId: 0,
            amount: getAssetAmount(0),
            primaryMarketId: 0,
            otherAddress: _receiver,
            secondaryMarketId: 0,
            otherAccountId: 0,
            data: _funcData
        });

        actions[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: getAssetAmount(_borrowAmount),
            primaryMarketId: daiMarketId,
            otherAddress: address(this),
            secondaryMarketId: 0,
            otherAccountId: 0,
            data: ""
        });

        soloMargin.operate(accounts, actions);
    }


    function getAssetAmount(uint _amount) internal returns (Types.AssetAmount memory amount) {
        amount = Types.AssetAmount({
            sign: false,
            denomination: Types.AssetDenomination.Wei,
            ref: Types.AssetReference.Delta,
            value: _amount
        });
    }

    function getAccount(address _user, uint _index) public view returns(Account.Info memory) {
        Account.Info memory account = Account.Info({
            owner: _user,
            number: _index
        });

        return account;
    }
}
