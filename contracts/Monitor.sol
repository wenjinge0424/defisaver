pragma solidity ^0.5.0;

import "./interfaces/TubInterface.sol";
import "./interfaces/ProxyRegistryInterface.sol";
import "./interfaces/ERC20.sol";
import "./DS/DSMath.sol";


contract Monitor is DSMath {

    // KOVAN
    PipInterface pip = PipInterface(0xA944bd4b25C9F186A846fd5668941AA3d3B8425F);
    TubInterface tub = TubInterface(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);
    ProxyRegistryInterface registry = ProxyRegistryInterface(0x64A436ae831C1672AE81F674CAb8B6775df3475C);
    address public constant VOX_ADDRESS = 0xBb4339c0aB5B1d9f14Bd6e3426444A1e9d86A1d9;

    address public saverProxy;
    address public owner;

    struct CdpHolder {
        uint minRatio;
        uint maxRatio;
        uint slippageLimit;
        uint optimalRatio;
        address owner;
    }

    mapping(bytes32 => CdpHolder) public holders;
    mapping(address => bool) public approvedCallers;

    event Subscribed(address indexed owner, bytes32 cdpId);
    event Unsubscribed(address indexed owner, bytes32 cdpId);

    event CdpRepay(bytes32 indexed cdpId, address caller);
    event CdpBoost(bytes32 indexed cdpId, address caller);

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
        saverProxy = 0x8bc58Dc76bB856Bf623d8483dC9590b3d6924ec9;
    }

    /// @dev Users DSProxy should call this
    function subscribe(bytes32 _cdpId, uint _minRatio, uint _maxRatio, uint _optimalRatio, uint _slippageLimit) public {
        require(isOwner(msg.sender, _cdpId));

        holders[_cdpId] = CdpHolder({
            minRatio: _minRatio,
            maxRatio: _maxRatio,
            optimalRatio: _optimalRatio,
            slippageLimit: _slippageLimit,
            owner: msg.sender
        });

        emit Subscribed(msg.sender, _cdpId);
    }

    function unsubscribe(bytes32 _cdpId) public {
        require(isOwner(msg.sender, _cdpId));

        delete holders[_cdpId];

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @dev Should be callable by onlyApproved
    function repayFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        CdpHolder memory holder = holders[_cdpId];

        require(holder.owner != address(0));
        require(getRatio(_cdpId) <= holders[_cdpId].minRatio);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("repay(bytes32,uint256,uint256,uint256)", _cdpId, _amount, 0, 2));

        emit CdpRepay(_cdpId, msg.sender);
    }

    /// @dev Should be callable by onlyApproved
    function boostFor(bytes32 _cdpId, uint _amount) public onlyApproved {
        CdpHolder memory holder = holders[_cdpId];

        require(holder.owner != address(0));

        require(getRatio(_cdpId) >= holders[_cdpId].maxRatio);

        DSProxyInterface(holder.owner).execute(saverProxy, abi.encodeWithSignature("boost(bytes32,uint256,uint256,uint256)", _cdpId, _amount, uint(-1), 2));

        emit CdpBoost(_cdpId, msg.sender);
    }

    // Owner only operations
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

    function getRatio(bytes32 _cdpId) public returns(uint) {
        return (rdiv(rmul(rmul(tub.ink(_cdpId), tub.tag()), WAD), tub.tab(_cdpId)));
    }

    function isOwner(address _owner, bytes32 _cdpId) internal returns(bool) {
        require(tub.lad(_cdpId) == _owner);
        
        return true;
    }
 }