// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";

import {ITrustlessActions, IDAO} from "../src/ITrustlessActions.sol";
import {TrustlessActionsMock} from "./mocks/TrustlessActionsMock.sol";
import {
    TrustlessManagementMock,
    NO_PERMISSION_CHECKER
} from "../lib/trustless-management/test/mocks/TrustlessManagementMock.sol";
import {DAOMock} from "../lib/trustless-management/test/mocks/DAOMock.sol";
import {ActionHelper} from "../lib/trustless-management/test/helpers/ActionHelper.sol";

contract TrustlessActionsTest is Test {
    DAOMock public dao;
    TrustlessManagementMock public trustlessManagement;
    TrustlessActionsMock public trustlessActions;
    uint256 constant role = 0;

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        trustlessActions = new TrustlessActionsMock();

        vm.startPrank(address(dao));
        trustlessManagement.changeFullAccess(dao, role, NO_PERMISSION_CHECKER);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_createAction(IDAO.Action[] calldata _actions, uint256 _failureMap, string calldata _metadata)
        external
    {
        vm.expectEmit(address(trustlessActions));
        // This has assumption that the first task will have id 0
        emit ITrustlessActions.ActionCreated(0, dao, trustlessManagement, role, _actions, _failureMap, _metadata);
        trustlessActions.createAction(trustlessManagement, role, _actions, _failureMap, _metadata);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_executeAction(
        uint256[] calldata _callableIndexes,
        bytes[] calldata _calldatas,
        bytes[] calldata _returnValues,
        uint256 _failureMap,
        address _executor
    ) external {
        vm.assume(_calldatas.length >= _callableIndexes.length);
        vm.assume(_returnValues.length >= _callableIndexes.length);
        ActionHelper actionHelper = new ActionHelper(_callableIndexes, _calldatas, _returnValues);
        vm.assume(actionHelper.isValid());

        IDAO.Action[] memory actions = actionHelper.getActions();
        uint32 id = trustlessActions.createAction(trustlessManagement, role, actions, _failureMap, "");
        bytes[] memory shortendReturnValues = new bytes[](actions.length);
        for (uint256 i; i < shortendReturnValues.length; i++) {
            shortendReturnValues[i] = _returnValues[i];
        }

        vm.stopPrank();
        vm.prank(_executor);
        vm.expectEmit(address(trustlessActions));
        emit ITrustlessActions.ActionExecuted(id, dao, _executor, shortendReturnValues, 0);
        trustlessActions.executeAction(dao, id);
    }
}
