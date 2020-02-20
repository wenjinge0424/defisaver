pragma solidity ^0.5.0;

import "../interfaces/TubInterface.sol";
import "../interfaces/ProxyRegistryInterface.sol";
import "../interfaces/GasTokenInterface.sol";
import "../interfaces/ERC20.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";


contract Monitor is DSMath, ConstantAddresses {
    // KOVAN
    PipInterface pip = PipInterface(PIP_INTERFACE_ADDRESS);
    TubInterface tub = TubInterface(TUB_ADDRESS);
    ProxyRegistryInterface registry = ProxyRegistryInterface(PROXY_REGISTRY_INTERFACE_ADDRESS);
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);

    uint256 public constant REPAY_GAS_TOKEN = 30;
    uint256 public constant BOOST_GAS_TOKEN = 19;

    uint256 public constant MAX_GAS_PRICE = 40000000000; // 40 gwei

    uint256 public constant REPAY_GAS_COST = 1500000;
    uint256 public constant BOOST_GAS_COST = 750000;

    address public saverProxy;
    address public owner;
    uint256 public changeIndex;

    struct CdpHolder {
        uint256 minRatio;
        uint256 maxRatio;
        uint256 optimalRatioBoost;
        uint256 optimalRatioRepay;
        address owner;
    }

    mapping(bytes32 => CdpHolder) public holders;

    /// @dev This will be Bot addresses which will trigger the calls
    mapping(address => bool) public approvedCallers;

    event Subscribed(address indexed owner, bytes32 cdpId);
    event Unsubscribed(address indexed owner, bytes32 cdpId);
    event Updated(address indexed owner, bytes32 cdpId);

    event CdpRepay(
        bytes32 indexed cdpId,
        address caller,
        uint256 _amount,
        uint256 _ratioBefore,
        uint256 _ratioAfter
    );
    event CdpBoost(
        bytes32 indexed cdpId,
        address caller,
        uint256 _amount,
        uint256 _ratioBefore,
        uint256 _ratioAfter
    );

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
    function subscribe(
        bytes32 _cdpId,
        uint256 _minRatio,
        uint256 _maxRatio,
        uint256 _optimalRatioBoost,
        uint256 _optimalRatioRepay
    ) public {
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
    function repayFor(bytes32 _cdpId, uint256 _amount) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint256 ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));
        require(ratioBefore <= holders[_cdpId].minRatio);

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        DSProxyInterface(holder.owner).execute(
            saverProxy,
            abi.encodeWithSignature("repay(bytes32,uint256,uint256)", _cdpId, _amount, gasCost)
        );

        uint256 ratioAfter = getRatio(_cdpId);

        require(ratioAfter > holders[_cdpId].minRatio);
        require(ratioAfter < holders[_cdpId].maxRatio);

        emit CdpRepay(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Dai to convert to Eth
    function boostFor(bytes32 _cdpId, uint256 _amount) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint256 ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));

        require(ratioBefore >= holders[_cdpId].maxRatio);

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        DSProxyInterface(holder.owner).execute(
            saverProxy,
            abi.encodeWithSignature("boost(bytes32,uint256,uint256)", _cdpId, _amount, gasCost)
        );

        uint256 ratioAfter = getRatio(_cdpId);

        require(ratioAfter > holders[_cdpId].minRatio);
        require(ratioAfter < holders[_cdpId].maxRatio);

        emit CdpBoost(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @notice Calculates the ratio of a given cdp
    /// @param _cdpId The id od the cdp
    function getRatio(bytes32 _cdpId) public returns (uint256) {
        return (rdiv(rmul(rmul(tub.ink(_cdpId), tub.tag()), WAD), tub.tab(_cdpId)));
    }

    /// @notice Check if the owner is the cup owner
    /// @param _owner Address which is the owner of the cup
    /// @param _cdpId Id of the cdp
    function isOwner(address _owner, bytes32 _cdpId) internal view returns (bool) {
        require(tub.lad(_cdpId) == _owner);

        return true;
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint256 _gasAmount) internal view returns (uint256) {
        uint256 gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

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
    function transferERC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

    /// @notice If any Eth gets stuck in the contract
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferEth(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
