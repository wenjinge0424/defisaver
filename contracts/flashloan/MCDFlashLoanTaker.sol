pragma solidity ^0.5.0;

import "../mcd/saver_proxy/MCDSaverProxy.sol";
import "../constants/ConstantAddresses.sol";

contract FlashLoanLogger {
    event FlashLoan(string, uint, uint, address);

    function logFlashLoan(string calldata _actionType, uint _id, uint _loanAmount, address _sender) external {
        emit FlashLoan(_actionType, _loanAmount, _id, _sender);
    }
}

contract IDaiToken {
    function flashBorrowToken(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data
    )
        external
        payable;
}

contract MCDFlashLoanTaker is ConstantAddresses, SaverProxyHelper {
    address public constant MCD_SAVER_FLASH_PROXY = 0x93b575d02982B5Fb4d0716298210997f2ddEe9ec;
    address public constant MCD_CLOSE_FLASH_PROXY = 0x5e8cd6069Fb7F3DD7Ae257f1833F1Df5B890154b;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    IDaiToken public constant IDAI = IDaiToken(NEW_IDAI_ADDRESS);
    FlashLoanLogger public constant logger = FlashLoanLogger(0x6c4114b65f90392e78Ef7c1f2c1FD33832d7965e);

    Vat public constant vat = Vat(VAT_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        // uint[6] memory _data,
        // address _joinAddr,
        // address _exchangeAddress,
        // bytes memory _callData

    function boostWithLoan(
        uint[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {

        uint maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));
        uint debtAmount = _data[1];

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 1);

         IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
            abi.encodeWithSignature('actionWithLoan(uint256[6],uint256,address,address,bytes,bool)',
                _data, loanAmount, _joinAddr, _exchangeAddress, _callData, false)
        );

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 0);

        logger.logFlashLoan('Boost', loanAmount, _data[0], msg.sender);
    }

    function repayWithLoan(
        uint[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {

        uint maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));

        uint ethPrice = getPrice(manager.ilks(_data[0]));
        uint debtAmount = rmul(_data[1], add(ethPrice, div(ethPrice, 10)));

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 1);

         IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
            abi.encodeWithSignature('actionWithLoan(uint256[6],uint256,address,address,bytes,bool)',
                _data, loanAmount, _joinAddr, _exchangeAddress, _callData, true)
        );

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_PROXY, 0);

        logger.logFlashLoan('Repay', loanAmount, _data[0], msg.sender);
    }

    function closeWithLoan(
        uint[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public {
        bytes32 ilk = manager.ilks(_data[0]);

        uint maxDebt = getMaxDebt(_data[0], ilk);

        (uint collateral,) = getCdpInfo(manager, _data[0], ilk);

        uint wholeDebt = getAllDebt(VAT_ADDRESS, manager.urns(_data[0]), manager.urns(_data[0]), ilk);

        // convert to eth

        require(wholeDebt > maxDebt, "No need for a flash loan");

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_PROXY, 1);

         IDAI.flashBorrowToken(wholeDebt, MCD_CLOSE_FLASH_PROXY, MCD_CLOSE_FLASH_PROXY, "",
            abi.encodeWithSignature('closeCDP(uint256[6],uint256,uint256,address,address,bytes)',
                                            _data, wholeDebt, collateral, _joinAddr, _exchangeAddress, _callData)
        );

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_PROXY, 0);

        logger.logFlashLoan('Close', wholeDebt, _data[0], msg.sender);

    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice(_ilk);

        (, uint mat) = spotter.ilks(_ilk);
        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }
}
