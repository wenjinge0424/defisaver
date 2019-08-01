pragma solidity ^0.5.0;

import "./DS/DSMath.sol";
import "./DS/DSAuth.sol";
import "./interfaces/TubInterface.sol";
import "./interfaces/ProxyRegistryInterface.sol";

/// @title Marketplace keeps track of all the CDPs and implements the buy logic through MarketplaceProxy
contract Marketplace is DSAuth, DSMath {

    struct SaleItem {
        address payable owner;
        address payable proxy;
        uint discount;
        bool active;
    }

    mapping (bytes32 => SaleItem) public items;
    mapping (bytes32 => uint) public itemPos;
    bytes32[] public itemsArr;

    address public marketplaceProxy;

    // 2 decimal percision when defining the disocunt value
    uint public fee = 100; //1% fee

    // KOVAN
    ProxyRegistryInterface public registry = ProxyRegistryInterface(0x64A436ae831C1672AE81F674CAb8B6775df3475C);
    TubInterface public tub = TubInterface(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);

    event OnSale(bytes32 indexed cup, address indexed proxy, address owner, uint discount);

    event Bought(bytes32 indexed cup, address indexed newLad, address indexed oldProxy,
                address oldOwner, uint discount);

    constructor(address _marketplaceProxy) public {
        marketplaceProxy = _marketplaceProxy;
    }

    /// @notice User calls this method to put a CDP on sale which he must own
    /// @dev Must be called by DSProxy contract in order to authorize for sale
    /// @param _cup Id of the CDP that is being put on sale
    /// @param _discount Discount of the original value, goes from 0 - 99% with 2 decimal percision
    function putOnSale(bytes32 _cup, uint _discount) public {
        require(isOwner(msg.sender, _cup), "msg.sender must be proxy which owns the cup");
        require(_discount < 10000 && _discount > 100, "can't have 100% discount and must be over 1%");
        require(tub.ink(_cup) > 0 && tub.tab(_cup) > 0, "must have collateral and debt to put on sale");
        require(!isOnSale(_cup), "can't put a cdp on sale twice");

        address payable owner = address(uint160(DSProxyInterface(msg.sender).owner()));

        items[_cup] = SaleItem({
            discount: _discount,
            proxy: msg.sender,
            owner: owner,
            active: true
        });

        itemsArr.push(_cup);
        itemPos[_cup] = itemsArr.length - 1;

        emit OnSale(_cup, msg.sender, owner, _discount);
    }

    /// @notice Any user can call this method to buy a CDP
    /// @dev This will fail if the CDP owner was changed
    /// @param _cup Id of the CDP you want to buy
    function buy(bytes32 _cup, address _newOwner) public payable {
        SaleItem storage item = items[_cup];

        require(item.active == true, "Check if cup is on sale");
        require(item.proxy == tub.lad(_cup), "The owner must stay the same");

        uint cdpPrice;
        uint feeAmount;

        (cdpPrice, feeAmount) = getCdpPrice(_cup);

        require(msg.value >= cdpPrice, "Check if enough ether is sent for this cup");

        item.active = false;

        // give the cup to the buyer, him becoming the lad that owns the cup
        DSProxyInterface(item.proxy).execute(marketplaceProxy,
            abi.encodeWithSignature("give(bytes32,address)", _cup, _newOwner));

        item.owner.transfer(sub(cdpPrice, feeAmount)); // transfer money to the seller

        msg.sender.transfer(sub(msg.value, cdpPrice));

        emit Bought(_cup, msg.sender, item.proxy, item.owner, item.discount);

        removeItem(_cup);

    }

    /// @notice Remove the CDP from the marketplace
    /// @param _cup Id of the CDP
    function cancel(bytes32 _cup) public {
        require(isOwner(msg.sender, _cup), "msg.sender must proxy which owns the cup");
        require(isOnSale(_cup), "only cancel cdps that are on sale");

        removeItem(_cup);
    }

    /// @notice A only owner functon which withdraws Eth balance
    function withdraw() public auth {
        msg.sender.transfer(address(this).balance);
    }

    /// @notice Calculates the price of the CDP given the discount and the fee
    /// @param _cup Id of the CDP
    /// @return It returns the price of the CDP and the amount needed for the contracts fee
    function getCdpPrice(bytes32 _cup) public returns(uint, uint) {
        SaleItem memory item = items[_cup];

        uint collateral = rmul(tub.ink(_cup), tub.per()); // collateral in Eth
        uint govFee = wdiv(rmul(tub.tab(_cup), rdiv(tub.rap(_cup), tub.tab(_cup))), uint(tub.pip().read()));
        uint debt = add(govFee, wdiv(tub.tab(_cup), uint(tub.pip().read()))); // debt in Eth

        uint difference = 0;

        if (item.discount > fee) {
            difference = sub(item.discount, fee);
        } else {
            difference = item.discount;
        }

        uint cdpPrice = mul(sub(collateral, debt), (sub(10000, difference))) / 10000;
        uint feeAmount = mul(sub(collateral, debt), fee) / 10000;

        return (cdpPrice, feeAmount);
    }

    /// @notice Used by front to fetch what is on sale
    /// @return Returns all CDP ids that are on sale and are not closed
    function getItemsOnSale() public view returns(bytes32[] memory arr) {
        uint n = 0;

        arr = new bytes32[](itemsArr.length);
        for (uint i = 0; i < itemsArr.length; ++i) {
            if (tub.lad(itemsArr[i]) != address(0)) {
                arr[n] = itemsArr[i];
                n++;
            }
        }

    }

    /// @notice Helper method to check if a CDP is on sale
    /// @return True|False depending if it is on sale
    function isOnSale(bytes32 _cup) public view returns (bool) {
        return items[_cup].active;
    }

    function removeItem(bytes32 _cup) internal {
        delete items[_cup];

        uint index = itemPos[_cup];
        itemsArr[index] = itemsArr[itemsArr.length - 1];

        itemPos[_cup] = 0;
        itemPos[itemsArr[itemsArr.length - 1]] = index;

        itemsArr.length--;
    }

    function isOwner(address _owner, bytes32 _cup) internal view returns(bool) {
        require(tub.lad(_cup) == _owner);

        return true;
    }

}
