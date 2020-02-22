pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "./FlashLoanReceiverBase.sol";

contract MCDCloseFlashLoan is MCDSaverProxy, FlashLoanReceiverBase {
    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(MANAGER_ADDRESS);

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5);

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params) 
    external {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve), 
            "Invalid balance for the contract");

        (
            uint256[6] memory data,
            uint256[4] memory debtData,
            address joinAddr,
            address exchangeAddress,
            bytes memory callData
        ) 
         = abi.decode(_params, (uint256[6],uint256[4],address,address,bytes));

        closeCDP(data, debtData, joinAddr, exchangeAddress, callData, _fee);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }


    function closeCDP(
        uint256[6] memory _data,
        uint[4] memory debtData,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint _fee
    ) internal {
        address payable owner = address(uint160(getOwner(manager, _data[0])));
        address collateralAddr = getCollateralAddr(_joinAddr);

        uint loanAmount = debtData[0];

        paybackDebt(_data[0], manager.ilks(_data[0]), debtData[0], owner); // payback whole debt
        drawCollateral(_data[0], manager.ilks(_data[0]), _joinAddr, debtData[2]);

        uint256 collAmount = getCollAmount(_data, loanAmount, collateralAddr);

        // collDrawn, minPrice, exchangeType, 0xPrice
        uint256[4] memory swapData = [collAmount, _data[2], _data[3], _data[5]];
        uint256 daiSwaped = swap(
            swapData,
            collateralAddr,
            DAI_ADDRESS,
            _exchangeAddress,
            _callData
        );

        require(daiSwaped >= (loanAmount + _fee), "We must exchange enough Dai tokens to repay loan");

        // If we swapped to much and have extra Dai
        if (daiSwaped > (loanAmount + _fee)) {
            // TODO: switch to Uniswap on MAINNET
            swap(
                [sub(daiSwaped, (loanAmount + _fee)), 0, 2, 1],
                DAI_ADDRESS,
                collateralAddr,
                address(0),
                _callData
            );
        }

        // Give user the leftover collateral
        if (collateralAddr == WETH_ADDRESS) {
            require(address(this).balance >= debtData[3], "Below min. number of eth specified");
            owner.transfer(address(this).balance);
        } else {
            uint256 tokenBalance = ERC20(collateralAddr).balanceOf(address(this));

            require(tokenBalance >= debtData[3], "Below min. number of collateral specified");
            ERC20(collateralAddr).transfer(owner, tokenBalance);
        }
    }

    function getCollAmount(uint256[6] memory _data, uint256 _loanAmount, address _collateralAddr)
        internal
        returns (uint256 collAmount)
    {
        (, uint256 collPrice) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(
            _data[1],
            _collateralAddr,
            DAI_ADDRESS,
            _data[2]
        );
        collPrice = sub(collPrice, collPrice / 100); // offset the price by 1%

        collAmount = wdiv(_loanAmount, collPrice);
    }

    function() external payable {}
}
