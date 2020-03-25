pragma solidity ^0.5.0;

import "./ISubscriptionsV2.sol";
import "./StaticV2.sol";
import "./MCDMonitorProxyV2.sol";
import "../../constants/ConstantAddresses.sol";
import "../../interfaces/GasTokenInterface.sol";
import "../../DS/DSMath.sol";
import "../maker/Manager.sol";
import "../maker/Vat.sol";
import "../maker/Spotter.sol";
import "../../auth/AdminAuth.sol";



/// @title Implements logic that allows bots to call Boost and Repay
contract MCDMonitorV2 is AdminAuth, ConstantAddresses, DSMath, StaticV2 {

    uint public REPAY_GAS_TOKEN = 30;
    uint public BOOST_GAS_TOKEN = 19;

    uint constant public MAX_GAS_PRICE = 80000000000; // 80 gwei

    uint public REPAY_GAS_COST = 2200000;
    uint public BOOST_GAS_COST = 1500000;

    MCDMonitorProxyV2 public monitorProxyContract;
    ISubscriptionsV2 public subscriptionsContract;
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);
    address public automaticSaverProxyAddress;

    Manager public manager = Manager(MANAGER_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Spotter public spotter = Spotter(SPOTTER_ADDRESS);

    /// @dev Addresses that are able to call methods for repay and boost
    mapping(address => bool) public approvedCallers;

    event CdpRepay(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio);
    event CdpBoost(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio);

    modifier onlyApproved() {
        require(approvedCallers[msg.sender]);
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _automaticSaverProxyAddress) public {
        approvedCallers[msg.sender] = true;

        monitorProxyContract = MCDMonitorProxyV2(_monitorProxy);
        subscriptionsContract = ISubscriptionsV2(_subscriptions);
        automaticSaverProxyAddress = _automaticSaverProxyAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _data Array of uints representing [cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _nextPrice Next price in Maker protocol
    /// @param _joinAddr Address of collateral join for specific CDP
    /// @param _exchangeAddress Address to call 0x exchange
    /// @param _callData Bytes representing call data for 0x exchange
    function repayFor(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        uint256 _nextPrice,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        uint ratioBefore;
        bool isAllowed;
        (isAllowed, ratioBefore) = canCall(Method.Repay, _data[0], _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        // calculated gas cost must be higher or equal with sent gasCost
        require(gasCost >= _data[4]);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_data[0]), automaticSaverProxyAddress, abi.encodeWithSignature("automaticRepay(uint256[6],address,address,bytes)", _data, _joinAddr, _exchangeAddress, _callData));

        uint ratioAfter;
        bool isGoodRatio;
        (isGoodRatio, ratioAfter) = ratioGoodAfter(Method.Repay, _data[0], _nextPrice);
        // doesn't allow user to repay too much
        require(isGoodRatio);

        emit CdpRepay(_data[0], msg.sender, _data[1], ratioBefore, ratioAfter);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _data Array of uints representing [cdpId, collateralAmount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _nextPrice Next price in Maker protocol
    /// @param _joinAddr Address of collateral join for specific CDP
    /// @param _exchangeAddress Address to call 0x exchange
    /// @param _callData Bytes representing call data for 0x exchange
    function boostFor(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        uint256 _nextPrice,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        uint ratioBefore;
        bool isAllowed;
        (isAllowed, ratioBefore) = canCall(Method.Boost, _data[0], _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        // calculated gas cost must be higher or equal with sent gasCost
        require(gasCost >= _data[4]);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_data[0]), automaticSaverProxyAddress, abi.encodeWithSignature("automaticBoost(uint256[6],address,address,bytes)", _data, _joinAddr, _exchangeAddress, _callData));

        uint ratioAfter;
        bool isGoodRatio;
        (isGoodRatio, ratioAfter) = ratioGoodAfter(Method.Boost, _data[0], _nextPrice);
        // doesn't allow user to boost too much
        require(isGoodRatio);

        emit CdpBoost(_data[0], msg.sender, _data[1], ratioBefore, ratioAfter);
    }

/******************* INTERNAL METHODS ********************************/
    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @notice Gets CDP info (collateral, debt)
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getCdpInfo(uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address urn = manager.urns(_cdpId);

        (uint collateral, uint debt) = vat.urns(_ilk, urn);
        (,uint rate,,,) = vat.ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _nextPrice Next price for user
    function getRatio(uint _cdpId, uint _nextPrice) public view returns (uint) {
        bytes32 ilk = manager.ilks(_cdpId);
        uint price = (_nextPrice == 0) ? getPrice(ilk) : _nextPrice;

        (uint collateral, uint debt) = getCdpInfo(_cdpId, ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt) / (10 ** 18);
    }

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by MCDMonitor to enforce the min/max check
    function canCall(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        uint128 minRatio;
        uint128 maxRatio;
        bool boost;
        address cdpOwner;

        (boost, minRatio, maxRatio, , , cdpOwner, , ) = subscriptionsContract.getSubscribedInfo(_cdpId);

        // check if boost and boost allowed
        if (_method == Method.Boost && !boost) return (false, 0);

        // check if owner is still owner
        if (getOwner(_cdpId) != cdpOwner) return (false, 0);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    function ratioGoodAfter(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        uint128 minRatio;
        uint128 maxRatio;

        (, minRatio, maxRatio, , , , , ) = subscriptionsContract.getSubscribedInfo(_cdpId);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) internal view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change the amount of gas token burned per function call
    /// @param _gasAmount Amount of gas token
    /// @param _isRepay Flag to know for which function we are setting the gas token amount
    function changeGasTokenAmount(uint _gasAmount, bool _isRepay) public onlyOwner {
        if (_isRepay) {
            REPAY_GAS_TOKEN = _gasAmount;
        } else {
            BOOST_GAS_TOKEN = _gasAmount;
        }
    }

    /// @notice Adds a new bot address which will be able to call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

    /// @notice If any tokens gets stuck in the contract owner can withdraw it
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

    /// @notice If any Eth gets stuck in the contract owner can withdraw it
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferEth(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
