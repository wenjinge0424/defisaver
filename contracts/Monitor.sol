pragma solidity ^0.5.0;

import "./interfaces/TubInterface.sol";
import "./interfaces/ProxyRegistryInterface.sol";
import "./interfaces/GasTokenInterface.sol";
import "./interfaces/ERC20.sol";
import "./DS/DSMath.sol";
import "./constants/ConstantAddresses.sol";

contract Monitor is DSMath, ConstantAddresses {

    // KOVAN
    PipInterface pip = PipInterface(PIP_INTERFACE_ADDRESS);
    TubInterface tub = TubInterface(TUB_ADDRESS);
    ProxyRegistryInterface registry = ProxyRegistryInterface(PROXY_REGISTRY_INTERFACE_ADDRESS);
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);

    uint constant public REPAY_GAS_TOKEN = 30;
    uint constant public BOOST_GAS_TOKEN = 19;

    uint constant public MAX_GAS_PRICE = 40000000000; // 40 gwei

    uint constant public REPAY_GAS_COST = 1500000;
    uint constant public BOOST_GAS_COST = 750000;

    address public saverProxy;
    address public owner;
    uint public changeIndex;

    struct CdpHolder {
        uint minRatio;
        uint maxRatio;
        uint optimalRatioBoost;
        uint optimalRatioRepay;
        address owner;
    }

    mapping(bytes32 => CdpHolder) public holders;

    /// @dev This will be Bot addresses which will trigger the calls
    mapping(address => bool) public approvedCallers;

    event Subscribed(address indexed owner, bytes32 cdpId);
    event Unsubscribed(address indexed owner, bytes32 cdpId);
    event Updated(address indexed owner, bytes32 cdpId);

    event CdpRepay(bytes32 indexed cdpId, address caller, uint _amount, uint _ratioBefore, uint _ratioAfter);
    event CdpBoost(bytes32 indexed cdpId, address caller, uint _amount, uint _ratioBefore, uint _ratioAfter);

    modifier onlyApproved() {
        require(approvedCallers[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(address _saverProxy) public {
        approvedCallers[msg.sender] = true;
        owner = msg.sender;

        saverProxy = _saverProxy;
        changeIndex = 0;
    }

    /// @notice Owners of Cdps subscribe through DSProxy for automatic saving
    /// @param _cdpId Id of the cdp
    /// @param _minRatio Minimum ratio that the Cdp can be
    /// @param _maxRatio Maximum ratio that the Cdp can be
    /// @param _optimalRatioBoost Optimal ratio for the user after boost is performed
    /// @param _optimalRatioRepay Optimal ratio for the user after repay is performed
    function subscribe(bytes32 _cdpId, uint _minRatio, uint _maxRatio, uint _optimalRatioBoost, uint _optimalRatioRepay) public {
        require(isOwner(msg.sender, _cdpId));

        bool isCreated = holders[_cdpId].owner == address(0) ? true : false;

        holders[_cdpId] = CdpHolder({
            minRatio: _minRatio,
            maxRatio: _maxRatio,
            optimalRatioBoost: _optimalRatioBoost,
            optimalRatioRepay: _optimalRatioRepay,
            owner: msg.sender
        });

        changeIndex++;

        if (isCreated) {
            emit Subscribed(msg.sender, _cdpId);
        } else {
            emit Updated(msg.sender, _cdpId);
        }
    }

    /// @notice Users can unsubscribe from monitoring
    /// @param _cdpId Id of the cdp
    function unsubscribe(bytes32 _cdpId) public {
        require(isOwner(msg.sender, _cdpId));

        delete holders[_cdpId];

        changeIndex++;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Eth to convert to Dai
    function repayFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));
        require(ratioBefore <= holders[_cdpId].minRatio);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("repay(bytes32,uint256,uint256)", _cdpId, _amount, gasCost));

        uint ratioAfter = getRatio(_cdpId);

        emit CdpRepay(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Dai to convert to Eth
    function boostFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));

        require(ratioBefore >= holders[_cdpId].maxRatio);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("boost(bytes32,uint256,uint256)", _cdpId, _amount, gasCost));

        uint ratioAfter = getRatio(_cdpId);

        emit CdpBoost(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }


    /// @notice Calculates the ratio of a given cdp
    /// @param _cdpId The id od the cdp
    function getRatio(bytes32 _cdpId) public returns(uint) {
        return (rdiv(rmul(rmul(tub.ink(_cdpId), tub.tag()), WAD), tub.tab(_cdpId)));
    }

    /// @notice Check if the owner is the cup owner
    /// @param _owner Address which is the owner of the cup
    /// @param _cdpId Id of the cdp
    function isOwner(address _owner, bytes32 _cdpId) internal view returns(bool) {
        require(tub.lad(_cdpId) == _owner);

        return true;
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
 }
