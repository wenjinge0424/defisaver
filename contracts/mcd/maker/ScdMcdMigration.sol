pragma solidity ^0.6.0;

import "../migration/SaiTubLike.sol";
import "./DaiJoin.sol";

abstract contract ScdMcdMigration {
    SaiTubLike public tub;
    DaiJoin public daiJoin;

    function swapSaiToDai(uint) virtual external;
    function swapDaiToSai(uint) virtual external;
    function migrate(bytes32) virtual external returns (uint);
}
