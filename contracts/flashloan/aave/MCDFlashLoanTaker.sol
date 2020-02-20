pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "../../constants/ConstantAddresses.sol";
import "../FlashLoanLogger.sol";

contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external;
}

contract LoanTaker is ConstantAddresses, SaverProxyHelper {

    address public constant MCD_SAVER_FLASH_PROXY = 0x93b575d02982B5Fb4d0716298210997f2ddEe9ec;
    address public constant MCD_CLOSE_FLASH_PROXY = 0xF6195D8d254bEF755fA8232D55Bb54B3b3eCf0Ce;
    address payable public constant MCD_OPEN_FLASH_PROXY = 0x22e37Df56cAFc7f33e9438751dff42DbD5CB8Ed6;

    ILendingPool lendingPool = ILendingPool(0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c);

    address payable public LOAN_RECEIVER = 0x2A4E1507Ef1cc9057bA6837d7d61Ca9546120DD2;

    function flashBorrow(uint _amount) public {
        lendingPool.flashLoan(LOAN_RECEIVER, DAI_ADDRESS, _amount,"");
    }

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
        uint256[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {
        uint256 maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));
        uint256 debtAmount = _data[1];

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint256 loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 1);

        // IDAI.flashBorrowToken(
        //     loanAmount,
        //     MCD_SAVER_FLASH_PROXY,
        //     MCD_SAVER_FLASH_PROXY,
        //     "",
        //     abi.encodeWithSignature(
        //         "actionWithLoan(uint256[6],uint256,address,address,bytes,bool)",
        //         _data,
        //         loanAmount,
        //         _joinAddr,
        //         _exchangeAddress,
        //         _callData,
        //         false
        //     )
        // );

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 0);

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

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 1);

        // IDAI.flashBorrowToken(
        //     loanAmount,
        //     MCD_SAVER_FLASH_PROXY,
        //     MCD_SAVER_FLASH_PROXY,
        //     "",
        //     abi.encodeWithSignature(
        //         "actionWithLoan(uint256[6],uint256,address,address,bytes,bool)",
        //         _data,
        //         loanAmount,
        //         _joinAddr,
        //         _exchangeAddress,
        //         _callData,
        //         true
        //     )
        // );

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 0);

        logger.logFlashLoan("Repay", loanAmount, _data[0], msg.sender);
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
