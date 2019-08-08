pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "../interfaces/KyberNetworkProxyInterface.sol";
import "../ConstantAddresses.sol";

contract CompoundMarginTrade is ConstantAddresses {

    struct Position {
        address _baseToken;
        uint _borrowedAmount;
        uint8 positionType; // 0 - long, 1 - short
        bool opened;
    }

    mapping (address => mapping(uint => Position)) positions;

    /// @notice Use Base token as collateral to borrow Dai, sell Dai for Base token
    /// @dev User needs to approve _baseToken so this contract can pull it
    function long(address _baseToken, address _cBaseToken, uint _collateralAmount, uint _amountToBorrow) public {
        CTokenInterface cBaseContract = CTokenInterface(_cBaseToken);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);

        cBaseContract.transferFrom(msg.sender, address(this), _collateralAmount);

        require(cDaiContract.borrow(_amountToBorrow) == 0);

        uint exchangedAmount = exchangeToken(ERC20(MAKER_DAI_ADDRESS), ERC20(_baseToken), _amountToBorrow, uint(-1));

        require(cBaseContract.mint(exchangedAmount) == 0);

    }

    function short() public {

    }

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
            msg.sender,
            _maxAmount,
            minRate,
            WALLET_ID
        );

        return destAmount;
    }
}
