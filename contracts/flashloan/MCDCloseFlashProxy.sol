pragma solidity ^0.5.0;

import "../mcd/saver_proxy/MCDSaverProxy.sol";

contract ManagerLike {
    function ilks(uint) public view returns (bytes32);
}

contract MCDCloseFlashProxy is MCDSaverProxy {

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    function closeCDP(
        uint[6] memory _data,
        uint _loanAmount,
        uint _collateral,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint _minEth
    ) public {

        // payback the CDP debt with loan amount
        address payable owner = address(uint160(getOwner(manager, _data[0])));

        paybackDebt(_data[0], manager.ilks(_data[0]), _loanAmount, owner);
        drawCollateral(_data[0], manager.ilks(_data[0]), _joinAddr, _collateral);

        (, uint ethPrice) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_data[1], getCollateralAddr(_joinAddr), DAI_ADDRESS, _data[2]);
        ethPrice = sub(ethPrice, ethPrice / 100); // offset the price by 1%

        uint ethAmount = wdiv(_loanAmount, ethPrice);

                                // collDrawn, minPrice, exchangeType, 0xPrice
        uint[4] memory swapData = [ethAmount, _data[2], _data[3], _data[5]];
        uint daiSwaped = swap(swapData, getCollateralAddr(_joinAddr), DAI_ADDRESS, _exchangeAddress, _callData);

        require(daiSwaped >= _loanAmount, "We must exchange enough Dai tokens");

        if (daiSwaped > _loanAmount) {
            // TODO: switch to Uniswap on MAINNET
            swap([sub(daiSwaped, _loanAmount), 0, 2, 1], DAI_ADDRESS, getCollateralAddr(_joinAddr), address(0), _callData);

        }

        ERC20(DAI_ADDRESS).transfer(address(NEW_IDAI_ADDRESS), _loanAmount);

        require(address(this).balance >= _minEth, "Below min. number of eth specified");

        owner.transfer(address(this).balance);
    }

    function() external payable {}

}
