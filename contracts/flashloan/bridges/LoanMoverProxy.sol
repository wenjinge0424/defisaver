pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";

import "../../interfaces/CTokenInterface.sol";
import "../../compound/helpers/CEtherInterface.sol";

contract ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
}

contract LoanMoverProxy is MCDSaverProxy {

    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function flashCompound2Maker(
        uint _cdpId,
        address _joinAddr,
        address _cCollateralAddr,
        bytes32 _ilk,
        uint _loanAmount,
        uint _fee
    ) internal {
        paybackCompound(DAI_ADDRESS, cDAI_ADDRESS, _loanAmount);

        uint redeemAmount = withdrawCompound(_cCollateralAddr);

        addCollateral(_cdpId, _joinAddr, redeemAmount);

        drawDai(_cdpId, _ilk, (_loanAmount + _fee));

        returnFlashLoan(DAI_ADDRESS, (_loanAmount + _fee));
    }

    function flashMaker2Compound(
        uint _cdpId,
        address _joinAddr,
        address _cCollateralAddr,
        bytes32 _ilk,
        uint _loanAmount,
        uint _fee
    ) internal {
        address owner = getOwner(manager, _cdpId);
        (uint collateral, ) = getCdpInfo(manager, _cdpId, _ilk);

        // repay dai debt cdp
        paybackDebt(_cdpId, _ilk, _loanAmount, owner);

        // withdraw collateral from cdp
        uint collDrawn = drawCollateral(_cdpId, _ilk, _joinAddr, collateral);

        // deposit in Compound
        depositCompound(getUnderlyingAddr(_cCollateralAddr), _cCollateralAddr, collDrawn);

        // borrow dai debt
        borrowCompound(DAI_ADDRESS, cDAI_ADDRESS, (_loanAmount + _fee));

        returnFlashLoan(DAI_ADDRESS, (_loanAmount + _fee));
    }

    function returnFlashLoan(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).transfer(msg.sender, _amount);
        }

        msg.sender.transfer(address(this).balance);
    }

    function paybackCompound(address _tokenAddr, address _cTokenAddr, uint _amount) internal {
        approveCToken(_tokenAddr, _cTokenAddr);

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).repayBorrow(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).repayBorrow.value(_amount)();
        }
    }

    function withdrawCompound(address _cTokenAddr) internal returns (uint redeemAmount) {
        uint cTokenBalance = CTokenInterface(_cTokenAddr).balanceOf(address(this));

        require(CTokenInterface(_cTokenAddr).redeem(cTokenBalance) == 0);

        redeemAmount = ERC20(getUnderlyingAddr(_cTokenAddr)).balanceOf(address(this));
    }

     function depositCompound(address _tokenAddr, address _cTokenAddr, uint _amount) internal {
        approveCToken(_tokenAddr, _cTokenAddr);

        enterMarket(_cTokenAddr);

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint.value(_amount)();
        }
    }

    function borrowCompound(address _tokenAddr, address _cTokenAddr, uint _amount) internal {
        enterMarket(_cTokenAddr);

        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);
    }

    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER).enterMarkets(markets);
    }

     function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    function approveCToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(_cTokenAddr, uint(-1));
        }
    }

}
