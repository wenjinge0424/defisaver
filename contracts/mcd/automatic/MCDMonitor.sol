pragma solidity ^0.5.0;

import "./ISubscriptions.sol";
import "./Static.sol";
import "./MCDMonitorProxy.sol";
import "../../constants/ConstantAddresses.sol";
import "../../interfaces/GasTokenInterface.sol";
import "../../DS/DSMath.sol";

contract MCDMonitor is ConstantAddresses, DSMath, Static {

    uint constant public REPAY_GAS_TOKEN = 30;
    uint constant public BOOST_GAS_TOKEN = 19;

    uint constant public MAX_GAS_PRICE = 40000000000; // 40 gwei

    uint constant public REPAY_GAS_COST = 1500000;
    uint constant public BOOST_GAS_COST = 750000;

    MCDMonitorProxy public monitorProxyContract;
    ISubscriptions public subscriptionsContract;
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);
    address public owner;
    address public mcdSaverProxyAddress;

    /// @dev This will be Bot addresses which will trigger the calls
    mapping(address => bool) public approvedCallers;

    event CdpRepay(uint indexed cdpId, address indexed caller, uint _amount);
    event CdpBoost(uint indexed cdpId, address indexed caller, uint _amount);

    modifier onlyApproved() {
        require(approvedCallers[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _mcdSaverProxyAddress) public {
        approvedCallers[msg.sender] = true;
        owner = msg.sender;

        monitorProxyContract = MCDMonitorProxy(_monitorProxy);
        subscriptionsContract = ISubscriptions(_subscriptions);
        mcdSaverProxyAddress = _mcdSaverProxyAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Eth to convert to Dai
    function repayFor(uint _cdpId, uint _amount, address _collateralJoin) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        require(subscriptionsContract.canCall(Method.Repay, _cdpId));

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_cdpId), mcdSaverProxyAddress, abi.encodeWithSignature("repay(uint256,address,uint256,uint256,uint256,uint256)", _cdpId, _collateralJoin, _amount, 0, 0, gasCost));

        require(subscriptionsContract.ratioGoodAfter(Method.Repay, _cdpId));

        emit CdpRepay(_cdpId, msg.sender, _amount);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Dai to convert to Eth
    function boostFor(uint _cdpId, uint _amount, address _collateralJoin) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        require(subscriptionsContract.canCall(Method.Boost, _cdpId));

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_cdpId), mcdSaverProxyAddress, abi.encodeWithSignature("boost(uint256,address,uint256,uint256,uint256,uint256)", _cdpId, _collateralJoin, _amount, 0, 0, gasCost));

        require(subscriptionsContract.ratioGoodAfter(Method.Boost, _cdpId));

        emit CdpBoost(_cdpId, msg.sender, _amount);
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) internal view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice Adds a new bot address which can call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removed a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

    /// @notice If any tokens gets stuck in the contract
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

    /// @notice If any Eth gets stuck in the contract
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferEth(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
