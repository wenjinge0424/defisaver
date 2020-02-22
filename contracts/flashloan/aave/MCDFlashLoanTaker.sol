pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "../../constants/ConstantAddresses.sol";
import "../FlashLoanLogger.sol";

contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external;

    function subscribersPos(uint256 _cdpId) external returns (uint256, bool);
}

contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external;
}

contract MCDFlashLoanTaker is ConstantAddresses, SaverProxyHelper {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0xb029791d7494A7620558779f8bEF51040Da9F3bf;
    address payable public constant MCD_CLOSE_FLASH_LOAN = 0x81E94a7727ee17dd95F4118e0a60cD15b022cA7b;
    address payable public constant MCD_OPEN_FLASH_LOAN = 0x2432316d1581b546490AbF73a81503D370846963;

    address public constant AAVE_DAI_ADDRESS = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    // address public constant MCD_CLOSE_FLASH_PROXY = 0xF6195D8d254bEF755fA8232D55Bb54B3b3eCf0Ce;
    // address payable public constant MCD_OPEN_FLASH_PROXY = 0x22e37Df56cAFc7f33e9438751dff42DbD5CB8Ed6;

    ILendingPool public constant lendingPool = ILendingPool(0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(MANAGER_ADDRESS);
    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0x6c4114b65f90392e78Ef7c1f2c1FD33832d7965e
    );

    // solhint-disable-next-line const-name-snakecase
    Vat public constant vat = Vat(VAT_ADDRESS);
    // solhint-disable-next-line const-name-snakecase
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    function boostWithLoan(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {
        uint256 maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));
        uint256 debtAmount = _data[1];

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint256 loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, loanAmount, _joinAddr, _exchangeAddress, _callData, false);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, AAVE_DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("Boost", loanAmount, _data[0], msg.sender);
    }

    function repayWithLoan(
        uint256[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {
        uint256 maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));

        uint256 ethPrice = getPrice(manager.ilks(_data[0]));
        uint256 debtAmount = rmul(_data[1], add(ethPrice, div(ethPrice, 10)));

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint256 loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, loanAmount, _joinAddr, _exchangeAddress, _callData, true);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, AAVE_DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("Repay", loanAmount, _data[0], msg.sender);
    }

    function closeWithLoan(
        uint256[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint256 _minCollateral
    ) public {
        bytes32 ilk = manager.ilks(_data[0]);

        uint256 maxDebt = getMaxDebt(_data[0], ilk);

        (uint256 collateral, ) = getCdpInfo(manager, _data[0], ilk);

        uint256 wholeDebt = getAllDebt(
            VAT_ADDRESS,
            manager.urns(_data[0]),
            manager.urns(_data[0]),
            ilk
        );

        require(wholeDebt > maxDebt, "No need for a flash loan");

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_LOAN, 1);

        uint[4] memory debtData = [wholeDebt, maxDebt, collateral, _minCollateral];
        bytes memory paramsData = abi.encode(_data, debtData, _joinAddr, _exchangeAddress, _callData);

        lendingPool.flashLoan(MCD_CLOSE_FLASH_LOAN, AAVE_DAI_ADDRESS, wholeDebt, paramsData);

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_LOAN, 0);

        // If sub. to automatic protection unsubscribe
        (, bool isSubscribed) = IMCDSubscriptions(SUBSCRIPTION_ADDRESS).subscribersPos(_data[0]);
        if (isSubscribed) {
            IMCDSubscriptions(SUBSCRIPTION_ADDRESS).unsubscribe(_data[0]);
        }

        logger.logFlashLoan("Close", wholeDebt, _data[0], msg.sender);
    }

    function openWithLoan(
        uint256[6] memory _data, // collAmount, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        bytes32 _ilk,
        address _collJoin,
        address _exchangeAddress,
        bytes memory _callData,
        address _proxy,
        bool _isEth
    ) public payable {
        if (_isEth) {
            MCD_OPEN_FLASH_LOAN.transfer(msg.value);
        } else {
            ERC20(getCollateralAddr(_collJoin)).transferFrom(msg.sender, address(this), _data[0]);
            ERC20(getCollateralAddr(_collJoin)).transfer(MCD_OPEN_FLASH_LOAN, _data[0]);
        }

        address[3] memory addrData = [_collJoin, _exchangeAddress, _proxy];

        bytes memory paramsData = abi.encode(_data, _ilk, addrData, _callData, _isEth);

        lendingPool.flashLoan(MCD_OPEN_FLASH_LOAN, AAVE_DAI_ADDRESS, _data[1], paramsData);

        logger.logFlashLoan("Open", manager.last(_proxy), _data[1], msg.sender);
    }


    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

}
