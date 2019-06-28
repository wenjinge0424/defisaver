pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "../interfaces/KyberNetworkProxyInterface.sol";

contract CompoundMarginTrade {

    address public constant CDAI_ADDRESS = 0xb6b09fBffBa6A5C4631e5F7B2e3Ee183aC259c0d;
    address public constant DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address constant KYBER_INTERFACE = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    address public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;


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

        uint exchangedAmount = exchangeToken(ERC20(DAI_ADDRESS), ERC20(_baseToken), _amountToBorrow, uint(-1));

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