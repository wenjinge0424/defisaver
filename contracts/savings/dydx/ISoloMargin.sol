pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./lib/Actions.sol";
import "./lib/Account.sol";
import "./lib/Types.sol";

contract ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public;

    function getAccountBalances(
        Account.Info memory account
    ) public view returns (
        address[] memory,
        Types.Par[] memory,
        Types.Wei[] memory
    );

    function setOperators(
        OperatorArg[] memory args
    ) public;
}
