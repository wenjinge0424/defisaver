pragma solidity ^0.5.0;

import "../mcd/saver_proxy/MCDSaverProxy.sol";
import "./MCDOpenProxyActions.sol";

contract MCDOpenFlashProxy is MCDSaverProxy {

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    address public constant OPEN_PROXY_ACTIONS = 0x9F579EA6250304f1256C7b2A54a2910B653E8C26;

    function openAndLeverage(
        uint[5] memory _data,
        bytes32 _ilk,
        address[3] memory addrData, // [_collJoin, _exchangeAddress, _proxy]
        bytes memory _callData,
        bool _isEth
    ) public {

        // Exchange the Dai loaned to Eth
        uint collSwaped = swap([_data[0], _data[1], _data[2], _data[4]],
             DAI_ADDRESS, getCollateralAddr(addrData[0]), addrData[1], _callData);

        if (_isEth) {
            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw.value(address(this).balance)(
                address(manager),
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                _ilk,
                _data[0],
                addrData[2]
            );
        } else {
        //      function openLockGemAndDraw(
        // address manager,
        // address jug,
        // address gemJoin,
        // address daiJoin,
        // bytes32 ilk,
        // uint wadC,
        // uint wadD,
        // bool transferFrom,
        // address owner
        }

         // Repay debt
        ERC20(DAI_ADDRESS).transfer(address(NEW_IDAI_ADDRESS), _data[0]);

    }

    function() external payable {}
}
