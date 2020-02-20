pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "../MCDOpenProxyActions.sol";


contract MCDOpenBZXFlashProxy is MCDSaverProxy {
    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(MANAGER_ADDRESS);

    address public constant OPEN_PROXY_ACTIONS = 0x9F579EA6250304f1256C7b2A54a2910B653E8C26;

    function openAndLeverage(
        uint256[6] memory _data,
        bytes32 _ilk,
        address[3] memory addrData, // [_collJoin, _exchangeAddress, _proxy]
        bytes memory _callData,
        bool _isEth
    ) public {
        // Exchange the Dai loaned to Eth
        // solhint-disable-next-line no-unused-vars
        uint256 collSwaped = swap(
            [_data[1], _data[2], _data[3], _data[4]],
            DAI_ADDRESS,
            getCollateralAddr(addrData[0]),
            addrData[1],
            _callData
        );

        if (_isEth) {
            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw.value(address(this).balance)(
                address(manager),
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                _ilk,
                _data[1],
                addrData[2]
            );
        } else {
            ERC20(getCollateralAddr(addrData[0])).approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                address(manager),
                JUG_ADDRESS,
                addrData[0],
                DAI_JOIN_ADDRESS,
                _ilk,
                _data[0],
                _data[1],
                true,
                addrData[2]
            );
        }

        // Repay debt
        ERC20(DAI_ADDRESS).transfer(address(NEW_IDAI_ADDRESS), _data[1]);
    }

    function() external payable {}
}
