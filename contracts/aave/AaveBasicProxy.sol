pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";

/// @title Basic compound interactions through the DSProxy
contract AaveBasicProxy is GasBurner {

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address public constant AAVE_LENDING_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _tokenAddr, uint _amount) public burnGas(0) payable {
        if (_tokenAddr != ETH_ADDR) {
            require(ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount));
            approveToken(_tokenAddr, AAVE_LENDING_POOL_CORE);
        }
        
        ILendingPool(AAVE_LENDING_POOL).deposit{value: msg.value}(_tokenAddr, _amount, AAVE_REFERRAL_CODE);

        ILendingPool(AAVE_LENDING_POOL).setUserUseReserveAsCollateral(_tokenAddr, true);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _aTokenAddr ATokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _wholeAmount If true we will take the whole amount on chain
    function withdraw(address _tokenAddr, address _aTokenAddr, uint _amount, bool _wholeAmount) public {
        uint amount = _wholeAmount ? ERC20(_aTokenAddr).balanceOf(msg.sender) : _amount;

        require(ERC20(_aTokenAddr).transferFrom(msg.sender, address(this), amount), "Returns false");
        IAToken(_aTokenAddr).redeem(amount);

        withdrawTokens(_tokenAddr);
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    function borrow(address _tokenAddr, uint _amount) public burnGas(0) {
        ILendingPool(AAVE_LENDING_POOL).borrow(_tokenAddr, _amount, 1, AAVE_REFERRAL_CODE);
        
        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _aTokenAddr, uint _amount, bool _wholeDebt) public burnGas(0) payable {
        uint amount = _amount;

        if (_wholeDebt) {
            (,amount,,,,,,,,) = ILendingPool(AAVE_LENDING_POOL).getUserReserveData(_aTokenAddr, address(this));
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).transferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, AAVE_LENDING_POOL_CORE);
        }

        ILendingPool(AAVE_LENDING_POOL).repay{value: msg.value}(_tokenAddr, amount, payable(address(this)));

        withdrawTokens(_tokenAddr);
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).transfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    /// @notice Enables or disables token to be used as collateral
    /// @param _tokenAddr Address of token 
    /// @param _enable Bool that determines if we allow or disallow address as collateral
    function setAsColalteral(address _tokenAddr, bool _enable) public {
        ILendingPool(AAVE_LENDING_POOL).setUserUseReserveAsCollateral(_tokenAddr, _enable);
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).approve(_caller, uint(-1));
        }
    }
}
