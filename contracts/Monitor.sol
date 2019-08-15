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

    address public saverProxy;
    address public owner;

    struct CdpHolder {
        uint minRatio;
        uint maxRatio;
        uint slippageLimit;
        uint optimalRatioBoost;
        uint optimalRatioRepay;
        address owner;
    }

    mapping(bytes32 => CdpHolder) public holders;

    uint public changeIndex;

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

    constructor() public {
        approvedCallers[msg.sender] = true;
        owner = msg.sender;
        saverProxy = 0x043125335E8feD7421F4aF91F7123b605b30F593;
        changeIndex = 0;
    }

    /// @dev Users DSProxy should call this
    function subscribe(bytes32 _cdpId, uint _minRatio, uint _maxRatio, uint _optimalRatioBoost, uint _optimalRatioRepay, uint _slippageLimit) public {
        require(isOwner(msg.sender, _cdpId));

        bool isCreated = holders[_cdpId].owner == address(0) ? true : false;

        holders[_cdpId] = CdpHolder({
            minRatio: _minRatio,
            maxRatio: _maxRatio,
            optimalRatioBoost: _optimalRatioBoost,
            optimalRatioRepay: _optimalRatioRepay,
            slippageLimit: _slippageLimit,
            owner: msg.sender
        });

        changeIndex++;

        if (isCreated) {
            emit Subscribed(msg.sender, _cdpId);
        } else {
            emit Updated(msg.sender, _cdpId);
        }
    }

    function unsubscribe(bytes32 _cdpId) public {
        require(isOwner(msg.sender, _cdpId));

        delete holders[_cdpId];

        changeIndex++;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @dev Should be callable by onlyApproved
    function repayFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        // require(tx.gasPrice <= 40000000000);
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));
        require(ratioBefore <= holders[_cdpId].minRatio);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("repay(bytes32,uint256,uint256,uint256)", _cdpId, _amount, 0, 2));

        uint ratioAfter = getRatio(_cdpId);

        emit CdpRepay(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @dev Should be callable by onlyApproved
    function boostFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        CdpHolder memory holder = holders[_cdpId];
        uint ratioBefore = getRatio(_cdpId);

        require(holder.owner != address(0));

        require(ratioBefore >= holders[_cdpId].maxRatio);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("boost(bytes32,uint256,uint256,uint256)", _cdpId, _amount, uint(-1), 2));

        uint ratioAfter = getRatio(_cdpId);

        emit CdpBoost(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    function getRatio(bytes32 _cdpId) public returns(uint) {
        return (rdiv(rmul(rmul(tub.ink(_cdpId), tub.tag()), WAD), tub.tab(_cdpId)));
    }

    function isOwner(address _owner, bytes32 _cdpId) internal returns(bool) {
        require(tub.lad(_cdpId) == _owner);

        return true;
    }

    // Owner only operations
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }
 }
