// pragma solidity ^0.5.0;

// import "../mcd/saver_proxy/MCDSaverProxy.sol";

// contract FlashLoanLogger {
//     event FlashLoan(string, uint, uint, address);

//     function logFlashLoan(string calldata _actionType, uint _id, uint _loanAmount, address _sender) external {
//         emit FlashLoan(_actionType, _loanAmount, _id, _sender);
//     }
// }

// contract IDaiToken {
//     function flashBorrowToken(
//         uint256 borrowAmount,
//         address borrower,
//         address target,
//         string calldata signature,
//         bytes calldata data
//     )
//         external
//         payable;
// }

// contract MCDFlashLoanTaker is DSMath, ConstantAddresses, SaverProxyHelper {
//     address public constant MCD_SAVER_FLASH_PROXY = 0xADe52ff4612B1654c6b8F4da30e1A7b853Bcac19;

//     Manager public constant manager = Manager(MANAGER_ADDRESS);
//     IDaiToken public constant IDAI = IDaiToken(NEW_IDAI_ADDRESS);
//     FlashLoanLogger public constant logger = FlashLoanLogger(0x6c4114b65f90392e78Ef7c1f2c1FD33832d7965e);

//     Vat public constant vat = Vat(VAT_ADDRESS);
//     Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

//     function boostWithLoan(
//         uint _cdpId,
//         address _joinAddr,
//         uint _daiAmount,
//         uint _minPrice,
//         uint _exchangeType,
//         uint _gasCost
//     ) external {
//         uint maxDebt = getMaxDebt(_cdpId, manager.ilks(_cdpId));
//         uint debtAmount = _daiAmount;

//         require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

//         uint loanAmount = sub(debtAmount, maxDebt);

//         manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 1);

//          IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
//             abi.encodeWithSignature('actionWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
//             _cdpId, _joinAddr, _daiAmount, loanAmount, _minPrice, _exchangeType, _gasCost, false)
//         );

//         manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 0);

//         logger.logFlashLoan('Boost', loanAmount, _cdpId, msg.sender);
//     }

//     function repayWithLoan(
//         uint _cdpId,
//         address _joinAddr,
//         uint _amount,
//         uint _minPrice,
//         uint _exchangeType,
//         uint _gasCost
//     ) external {
//         uint maxDebt = getMaxDebt(_cdpId, manager.ilks(_cdpId));

//         uint ethPrice = getPrice(manager.ilks(_cdpId));
//         uint debtAmount = rmul(_amount, add(ethPrice, div(ethPrice, 10)));

//         require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

//         uint loanAmount = sub(debtAmount, maxDebt);

//         manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 1);

//          IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
//             abi.encodeWithSignature('actionWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
//             _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, true)
//         );

//         manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 0);

//         logger.logFlashLoan('Repay', loanAmount, _cdpId, msg.sender);
//     }

//     function closeWithLoan(uint _cdpId) external {
//         bytes32 ilk = manager.ilks(_cdpId);

//         uint maxDebt = getMaxDebt(_cdpId, ilk);

//         (, uint wholeDebt) = getCdpInfo(manager, _cdpId, ilk);

//         uint loanAmount = sub(wholeDebt, maxDebt);

//         // convert to eth

//         // require(maxDebt >= wholeDebt, "No need for a flash loan");

//         // manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 1);

//         //  IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
//         //     abi.encodeWithSignature('actionWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
//         //     _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, true)
//         // );

//         // manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 0);

//         // logger.logFlashLoan('Close', loanAmount, _cdpId, msg.sender);

//     }

//     /// @notice Gets the maximum amount of debt available to generate
//     /// @param _cdpId Id of the CDP
//     /// @param _ilk Ilk of the CDP
//     function getMaxDebt(uint _cdpId, bytes32 _ilk) public view returns (uint) {
//         uint price = getPrice(_ilk);

//         (, uint mat) = spotter.ilks(_ilk);
//         (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

//         return sub(wdiv(wmul(collateral, price), mat), debt);
//     }

//     /// @notice Gets a price of the asset
//     /// @param _ilk Ilk of the CDP
//     function getPrice(bytes32 _ilk) public view returns (uint) {
//         (, uint mat) = spotter.ilks(_ilk);
//         (,,uint spot,,) = vat.ilks(_ilk);

//         return rmul(rmul(spot, spotter.par()), mat);
//     }
// }

// contract MCDSaverFlashProxy is MCDSaverProxy {

//     IDaiToken public constant IDAI = IDaiToken(NEW_IDAI_ADDRESS);
//     Manager public constant manager = Manager(MANAGER_ADDRESS);

//     function actionWithLoan(
//         uint _cdpId,
//         address _joinAddr,
//         uint _amount,
//         uint _loanAmount,
//         uint _minPrice,
//         uint _exchangeType,
//         uint _gasCost,
//         bool isRepay
//     ) public {

//         // payback the CDP debt with loan amount
//         address owner = getOwner(manager, _cdpId);
//         paybackDebt(_cdpId, manager.ilks(_cdpId), _loanAmount, owner);

//         if (isRepay) {
//             repay(_cdpId, _joinAddr, _amount, _minPrice, _exchangeType, _gasCost);
//         } else {
//             boost(_cdpId, _joinAddr, _amount, _minPrice, _exchangeType, _gasCost);
//         }

//         // repay the flash loan
//         uint daiDrawn = drawDai(_cdpId, manager.ilks(_cdpId), _loanAmount);

//         require(daiDrawn >= _loanAmount, "Loan debt to big for CDP");

//         ERC20(DAI_ADDRESS).transfer(address(IDAI), _loanAmount);
//     }

//     function() external payable {}

// }
