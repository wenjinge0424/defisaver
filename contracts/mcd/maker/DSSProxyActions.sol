pragma solidity ^0.5.0;

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract ManagerLike {
    function cdpCan(address, uint, address) public view returns (uint);
    function ilks(uint) public view returns (bytes32);
    function owns(uint) public view returns (address);
    function urns(uint) public view returns (address);
    function vat() public view returns (address);
    function open(bytes32) public returns (uint);
    function give(uint, address) public;
    function cdpAllow(uint, address, uint) public;
    function urnAllow(address, uint) public;
    function frob(uint, int, int) public;
    function frob(uint, address, int, int) public;
    function flux(uint, address, uint) public;
    function move(uint, address, uint) public;
    function exit(address, uint, address, uint) public;
    function quit(uint, address) public;
    function enter(address, uint) public;
    function shift(uint, uint) public;
}

contract VatLike {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract GemJoinLike {
    function dec() public returns (uint);
    function gem() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract GNTJoinLike {
    function bags(address) public view returns (address);
    function make(address) public returns (address);
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract HopeLike {
    function hope(address) public;
    function nope(address) public;
}

contract EndLike {
    function fix(bytes32) public view returns (uint);
    function cash(bytes32, uint) public;
    function free(bytes32) public;
    function pack(uint) public;
    function skim(bytes32, address) public;
}

contract JugLike {
    function drip(bytes32) public;
}

contract PotLike {
    function chi() public view returns (uint);
    function pie(address) public view returns (uint);
    function drip() public;
    function join(uint) public;
    function exit(uint) public;
}

contract ProxyRegistryLike {
    function proxies(address) public view returns (address);
    function build(address) public returns (address);
}

contract ProxyLike {
    function owner() public view returns (address);
}

contract DssProxyActions {
    function daiJoin_join(address apt, address urn, uint wad) public;
    function transfer(address gem, address dst, uint wad) public;
    function ethJoin_join(address apt, address urn) public payable;
    function gemJoin_join(address apt, address urn, uint wad, bool transferFrom) public payable;

    function hope(address obj, address usr) public;
    function nope(address obj, address usr) public;

    function open(address manager, bytes32 ilk) public returns (uint cdp);
    function give(address manager, uint cdp, address usr) public;
    function giveToProxy(address proxyRegistry, address manager, uint cdp, address dst) public;

    function cdpAllow(address manager, uint cdp, address usr, uint ok) public;
    function urnAllow(address manager, address usr, uint ok) public;
    function flux(address manager, uint cdp, address dst, uint wad) public;
    function move(address manager, uint cdp, address dst, uint rad) public;
    function frob(address manager, uint cdp, int dink, int dart) public;
    function frob(address manager, uint cdp, address dst, int dink, int dart) public;
    function quit(address manager, uint cdp, address dst) public;
    function enter(address manager, address src, uint cdp) public;
    function shift(address manager, uint cdpSrc, uint cdpOrg) public;
    function makeGemBag(address gemJoin) public returns (address bag);

    function lockETH(address manager, address ethJoin, uint cdp) public payable;
    function safeLockETH(address manager, address ethJoin, uint cdp, address owner) public payable;
    function lockGem(address manager, address gemJoin, uint cdp, uint wad, bool transferFrom) public;
    function safeLockGem(address manager, address gemJoin, uint cdp, uint wad, bool transferFrom, address owner) public;
    function freeETH(address manager, address ethJoin, uint cdp, uint wad) public;
    function freeGem(address manager, address gemJoin, uint cdp, uint wad) public;
    function draw(address manager, address jug, address daiJoin, uint cdp, uint wad) public;

    function wipe(address manager, address daiJoin, uint cdp, uint wad) public;
    function safeWipe(address manager, address daiJoin, uint cdp, uint wad, address owner) public;
    function wipeAll(address manager, address daiJoin, uint cdp) public;
    function safeWipeAll(address manager, address daiJoin, uint cdp, address owner) public;
    function lockETHAndDraw(address manager, address jug, address ethJoin, address daiJoin, uint cdp, uint wadD) public payable;
    function openLockETHAndDraw(address manager, address jug, address ethJoin, address daiJoin, bytes32 ilk, uint wadD) public payable returns (uint cdp);
    function lockGemAndDraw(address manager, address jug, address gemJoin, address daiJoin, uint cdp, uint wadC, uint wadD, bool transferFrom) public;
    function openLockGemAndDraw(address manager, address jug, address gemJoin, address daiJoin, bytes32 ilk, uint wadC, uint wadD, bool transferFrom) public returns (uint cdp);

    function openLockGNTAndDraw(address manager, address jug, address gntJoin, address daiJoin, bytes32 ilk, uint wadC, uint wadD) public returns (address bag, uint cdp);
    function wipeAndFreeETH(address manager, address ethJoin, address daiJoin, uint cdp, uint wadC, uint wadD) public;
    function wipeAllAndFreeETH(address manager, address ethJoin, address daiJoin, uint cdp, uint wadC) public;
    function wipeAndFreeGem(address manager, address gemJoin, address daiJoin, uint cdp, uint wadC, uint wadD) public;
    function wipeAllAndFreeGem(address manager, address gemJoin, address daiJoin, uint cdp, uint wadC) public;
}

