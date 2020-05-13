pragma solidity ^0.6.0;

import "../constants/SaverExchangeConstantAddresses.sol";
import "../interfaces/ERC20.sol";
import "../mcd/Discount.sol";

contract SaverExchangeHelper is SaverExchangeConstantAddresses {

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == DGD_ADDRESS) return 9;

        return ERC20(_token).decimals();
    }

    function pullTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            require(
                ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount),
                "Not able to withdraw wanted amount"
            );
        }
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {
        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).transfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).transfer(_to, getBalance(_destAddr));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    /// @notice Converts Weth -> Kybers Eth address
    /// @param _src Input address
    function wethToEth(address _src) internal pure returns (address) {
        return _src == WETH_ADDRESS ? KYBER_ETH_ADDRESS : _src;
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}
