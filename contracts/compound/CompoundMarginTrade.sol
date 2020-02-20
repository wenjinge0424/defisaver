pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "../interfaces/KyberNetworkProxyInterface.sol";
import "../constants/ConstantAddresses.sol";


contract CompoundMarginTrade is ConstantAddresses {
    struct Position {
        address _baseToken;
        uint256 _borrowedAmount;
        uint8 positionType; // 0 - long, 1 - short
        bool opened;
    }

    mapping(address => mapping(uint256 => Position)) positions;

    /// @notice Use Base token as collateral to borrow Dai, sell Dai for Base token
    /// @dev User needs to approve _baseToken so this contract can pull it
    function long(
        address _baseToken,
        address _cBaseToken,
        uint256 _collateralAmount,
        uint256 _amountToBorrow
    ) public {
        CTokenInterface cBaseContract = CTokenInterface(_cBaseToken);
        CTokenInterface cDaiContract = CTokenInterface(CDAI_ADDRESS);

        cBaseContract.transferFrom(msg.sender, address(this), _collateralAmount);

        require(cDaiContract.borrow(_amountToBorrow) == 0);

        uint256 exchangedAmount = exchangeToken(
            ERC20(MAKER_DAI_ADDRESS),
            ERC20(_baseToken),
            _amountToBorrow,
            uint256(-1)
        );

        require(cBaseContract.mint(exchangedAmount) == 0);
    }

    // solhint-disable-next-line no-empty-blocks
    function short() public {}

    function exchangeToken(
        ERC20 _sourceToken,
        ERC20 _destToken,
        uint256 _sourceAmount,
        uint256 _maxAmount
    ) internal returns (uint256 destAmount) {
        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        uint256 minRate;
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
