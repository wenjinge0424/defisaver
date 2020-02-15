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
        uint _minCollateral
    ) public {

        address payable owner = address(uint160(getOwner(manager, _data[0])));
        address collateralAddr = getCollateralAddr(_joinAddr);

        paybackDebt(_data[0], manager.ilks(_data[0]), _loanAmount, owner);
        drawCollateral(_data[0], manager.ilks(_data[0]), _joinAddr, _collateral);

        uint collAmount = getCollAmount(_data, _loanAmount, collateralAddr);

                                // collDrawn, minPrice, exchangeType, 0xPrice
        uint[4] memory swapData = [collAmount, _data[2], _data[3], _data[5]];
        uint daiSwaped = swap(swapData, collateralAddr, DAI_ADDRESS, _exchangeAddress, _callData);

        require(daiSwaped >= _loanAmount, "We must exchange enough Dai tokens to repay loan");

        // If we swapped to much and have extra Dai
        if (daiSwaped > _loanAmount) {
            // TODO: switch to Uniswap on MAINNET
            swap([sub(daiSwaped, _loanAmount), 0, 2, 1], DAI_ADDRESS, collateralAddr, address(0), _callData);
        }

        // Repay debt
        ERC20(DAI_ADDRESS).transfer(address(NEW_IDAI_ADDRESS), _loanAmount);

        // Give user the leftover collateral
        if (collateralAddr == WETH_ADDRESS) {
            require(address(this).balance >= _minCollateral, "Below min. number of eth specified");
            owner.transfer(address(this).balance);
        } else {
            uint tokenBalance = ERC20(collateralAddr).balanceOf(address(this));

            require(tokenBalance >= _minCollateral, "Below min. number of collateral specified");
            ERC20(collateralAddr).transfer(owner, tokenBalance);
        }
    }

    function getCollAmount(uint[6] memory _data, uint _loanAmount, address _collateralAddr) internal returns (uint collAmount) {
        (, uint collPrice) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_data[1], _collateralAddr, DAI_ADDRESS, _data[2]);
        collPrice = sub(collPrice, collPrice / 100); // offset the price by 1%

        collAmount = wdiv(_loanAmount, collPrice);
    }

    function() external payable {}

}
