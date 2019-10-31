pragma solidity ^0.5.0;

import "../migration/SaiTubLike.sol";
import "./DaiJoin.sol";

contract ScdMcdMigration {
    SaiTubLike public tub;
    DaiJoin public daiJoin;

    function swapSaiToDai(uint) external;
    function swapDaiToSai(uint) external;
    function migrate(bytes32) external returns (uint);
}
