pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../DS/DSProxy.sol";
import "../utils/Discount.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPoolV2.sol";
import "../interfaces/IPriceOracleGetterAave.sol";
import "../interfaces/IAaveProtocolDataProviderV2.sol";

import "../utils/SafeERC20.sol";
import "../utils/BotRegistry.sol";

contract AaveHelperV2 is DSMath {

    using SafeERC20 for ERC20;

    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

	address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint public constant NINETY_NINE_PERCENT_WEI = 990000000000000000;
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @notice Calculates the gas cost for transaction
    /// @param _oracleAddress address of oracle used
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return gasCost The amount we took for the gas cost
    function getGasCost(address _oracleAddress, uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint gasCost) {
        if (_gasCost != 0) {
            uint256 price = IPriceOracleGetterAave(_oracleAddress).getAssetPrice(_tokenAddr);

            _gasCost = wdiv(_gasCost, price) / (10 ** (18 - _getDecimals(_tokenAddr)));

            gasCost = _gasCost;
        }

        // gas cost can't go over 10% of the whole amount
        if (gasCost > (_amount / 10)) {
            gasCost = _amount / 10;
        }

        if (_tokenAddr == ETH_ADDR) {
            WALLET_ADDR.transfer(gasCost);
        } else {
            ERC20(_tokenAddr).safeTransfer(WALLET_ADDR, gasCost);
        }
    }


    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(payable(address(this)));

        return proxy.owner();
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    /// @notice Send specific amount from contract to specific user
    /// @param _token Token we are trying to send
    /// @param _user User that should receive funds
    /// @param _amount Amount that should be sent
    function sendContractBalance(address _token, address _user, uint _amount) internal {
        if (_amount == 0) return;

        if (_token == ETH_ADDR) {
            payable(_user).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_user, _amount);
        }
    }

    function sendFullContractBalance(address _token, address _user) internal {
        if (_token == ETH_ADDR) {
            sendContractBalance(_token, _user, address(this).balance);
        } else {
            sendContractBalance(_token, _user, ERC20(_token).balanceOf(address(this)));
        }
    }

    function _getDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return ERC20(_token).decimals();
    }

    function getDataProvider(address _market) internal view returns(IAaveProtocolDataProviderV2) {
        return IAaveProtocolDataProviderV2(ILendingPoolAddressesProviderV2(_market).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000));
    }
}
