pragma solidity ^0.6.0;

import "../constants/SaverExchangeConstantAddresses.sol";
import "../interfaces/ERC20.sol";
import "../mcd/Discount.sol";

contract SaverExchangeHelper {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DGD_ADDRESS = 0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A;

    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    address public constant KYBER_WRAPPER = 0x5b1869D9A4C187F2EAa108f3062412ecf0526b24;
    address public constant UNISWAP_WRAPPER = 0xCfEB869F69431e42cdB54A4F4f105C19C080A601;
    address public constant OASIS_WRAPPER = 0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab;
    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == DGD_ADDRESS) return 9;
        if (_token == KYBER_ETH_ADDRESS) return 18;

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

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}
